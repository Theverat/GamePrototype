using Godot;

public partial class TestMultiMesh : MultiMeshInstance3D
{
	private ulong startTime;
	private const int gridSize = 200;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready() {
		startTime = Time.GetTicksMsec();

		// Create the multimesh.
		//Multimesh = new MultiMesh();
		// Set the format first.
		//Multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform3D;
		// Then resize (otherwise, changing the format is not allowed)
		Multimesh.InstanceCount = gridSize * gridSize;
		// Maybe not all of them should be visible at first.
		//Multimesh.VisibleInstanceCount = 1000;

		// Set the transform of the instances.
		float offset = 1f;

		for (int i = 0; i < Multimesh.InstanceCount; i++) {
			int x = i % gridSize;
			int z = i / gridSize;
			Multimesh.SetInstanceTransform(i, new Transform3D(Basis.Identity, new Vector3(x * offset, 0, z * offset)));
		}
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta) {
		ulong processStart = Time.GetTicksMsec();
		float elapsed = (processStart - startTime) / 1000f;

		for (int i = 0; i < Multimesh.InstanceCount; i++) {
			int x = i % gridSize;
			int z = i / gridSize;

			var transform = Multimesh.GetInstanceTransform(i);
			transform.Origin.Y = Mathf.Sin(x * 0.3f + elapsed) + Mathf.Cos(z * 0.6f + elapsed * 0.7f);
			//var origin = transform.Origin;
			//transform.Origin = new Vector3(origin.X, Mathf.Sin(elapsed), origin.Z);
			Multimesh.SetInstanceTransform(i, transform);
		}

		GD.Print($"Instance Transform took {Time.GetTicksMsec() - processStart} ms");
	}
}
