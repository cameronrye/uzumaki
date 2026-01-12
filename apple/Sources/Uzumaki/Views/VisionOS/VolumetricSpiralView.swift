#if os(visionOS)
import RealityKit
import SwiftUI
import UzumakiCore

/// A volumetric spiral view for visionOS using RealityView
@available(visionOS 1.0, *)
public struct VolumetricSpiralView: View {
    @Binding var params: SpiralParams3D
    @Binding var colors: [Color]

    @State private var spiralEntity: ModelEntity?
    @State private var isGenerating = false

    public init(params: Binding<SpiralParams3D>, colors: Binding<[Color]>) {
        self._params = params
        self._colors = colors
    }

    public var body: some View {
        RealityView { content in
            // Create initial spiral entity
            if let entity = try? await createSpiralEntity() {
                content.add(entity)
                spiralEntity = entity
            }
        } update: { content in
            // Update spiral when parameters change
            Task {
                await updateSpiral(in: content)
            }
        }
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    guard let entity = spiralEntity else { return }
                    let translation = value.translation3D
                    entity.position += SIMD3<Float>(
                        Float(translation.x) * 0.001,
                        Float(translation.y) * 0.001,
                        Float(translation.z) * 0.001
                    )
                }
        )
        .gesture(
            RotateGesture3D()
                .targetedToAnyEntity()
                .onChanged { value in
                    guard let entity = spiralEntity else { return }
                    let rotation = value.rotation
                    entity.orientation = simd_quatf(
                        angle: Float(rotation.angle.radians),
                        axis: SIMD3<Float>(
                            Float(rotation.axis.x),
                            Float(rotation.axis.y),
                            Float(rotation.axis.z)
                        )
                    )
                }
        )
        .gesture(
            MagnifyGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    guard let entity = spiralEntity else { return }
                    let scale = Float(value.magnification)
                    entity.scale = SIMD3<Float>(repeating: scale)
                }
        )
    }

    // MARK: - Entity Creation

    private func createSpiralEntity() async throws -> ModelEntity {
        let meshData = try await generateMeshData()
        let mesh = try createMeshResource(from: meshData)
        let material = createMaterial()

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.components.set(InputTargetComponent())
        entity.components.set(CollisionComponent(shapes: [.generateConvex(from: mesh)]))

        return entity
    }

    private func updateSpiral(in content: RealityViewContent) async {
        guard !isGenerating, let existingEntity = spiralEntity else { return }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let meshData = try await generateMeshData()
            let mesh = try createMeshResource(from: meshData)
            let material = createMaterial()

            // Preserve transform
            let transform = existingEntity.transform

            // Create new entity
            let newEntity = ModelEntity(mesh: mesh, materials: [material])
            newEntity.transform = transform
            newEntity.components.set(InputTargetComponent())
            newEntity.components.set(CollisionComponent(shapes: [.generateConvex(from: mesh)]))

            // Replace in scene
            content.remove(existingEntity)
            content.add(newEntity)
            spiralEntity = newEntity
        } catch {
            print("Failed to update spiral: \(error)")
        }
    }

    // MARK: - Mesh Generation

    private func generateMeshData() async throws -> SpiralMeshData {
        try await Task.detached(priority: .userInitiated) {
            let points3D = SpiralGenerator3D.generate(params: params)
            let gradient = createGradient(from: colors)
            return try TubeMeshGenerator.generate(
                from: points3D,
                gradient: gradient,
                tubeRadius: params.tubeRadius,
                tubeSegments: 16
            )
        }.value
    }

    private func createGradient(from colors: [Color]) -> UzumakiCore.Gradient {
        let gradientColors = colors.map { color -> GradientColor in
            let resolved = color.resolve(in: EnvironmentValues())
            return GradientColor(
                r: resolved.red,
                g: resolved.green,
                b: resolved.blue,
                a: resolved.opacity
            )
        }
        return UzumakiCore.Gradient(colors: gradientColors.isEmpty
            ? [GradientColor(r: 1, g: 1, b: 1)]
            : gradientColors)
    }

    private func createMeshResource(from meshData: SpiralMeshData) throws -> MeshResource {
        var descriptor = MeshDescriptor(name: "VolumetricSpiral")
        descriptor.positions = MeshBuffer(meshData.positions)
        descriptor.normals = MeshBuffer(meshData.normals)
        descriptor.textureCoordinates = MeshBuffer(meshData.uvs)
        descriptor.primitives = .triangles(meshData.indices)
        return try MeshResource.generate(from: [descriptor])
    }

    private func createMaterial() -> SimpleMaterial {
        guard let firstColor = colors.first else {
            return SimpleMaterial(color: .white, isMetallic: true)
        }
        let resolved = firstColor.resolve(in: EnvironmentValues())
        let color = UIColor(red: CGFloat(resolved.red), green: CGFloat(resolved.green),
                           blue: CGFloat(resolved.blue), alpha: CGFloat(resolved.opacity))
        return SimpleMaterial(color: color, isMetallic: true)
    }
}
#endif

