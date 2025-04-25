using Godot;

[Tool]
public partial class RocketTurret : Node3D
{
	[Export]
	public Node3D Target;
	[Export]
	public Node3D CentralPillar;  // Only rotates around Y axis
	[Export]
	public Node3D RocketTubes;  // Only rotates around X axis
	[Export]
	public Node3D BulletPlane;

	public override void _Ready() {
	}

	public override void _Process(double delta) {
		AimAtTarget();
		Fire();
	}

	// TODO limit rotation speed
	// TODO make reusable?
	private void AimAtTarget() {
		if (Target == null)
			return;

		var globalPos = CentralPillar.GlobalTransform.Origin;
		var targetPos = Target.GlobalTransform.Origin;
		var oldRotation = CentralPillar.GlobalTransform.Basis.GetRotationQuaternion();
		var wTransform = CentralPillar.GlobalTransform.LookingAt(new Vector3(targetPos.X, globalPos.Y, targetPos.Z), Vector3.Up);
		var newRotation = new Quaternion(wTransform.Basis);
		var wRotation = oldRotation.Slerp(newRotation, 0.1f);
		CentralPillar.GlobalBasis = new Basis(wRotation);

		var tubeTransform = RocketTubes.GlobalTransform.LookingAt(targetPos, Vector3.Up);
		var tubeRotation = new Quaternion(tubeTransform.Basis);
		var tubeWRotation = RocketTubes.GlobalTransform.Basis.GetRotationQuaternion().Slerp(tubeRotation, 0.1f);
		RocketTubes.GlobalBasis = new Basis(tubeWRotation);
	}

	private void Fire() {
		if (BulletPlane == null)
			return;

		float maxDist = 200f;

		var origin = RocketTubes.GlobalPosition;
		var end = origin - RocketTubes.GlobalTransform.Basis.Z * maxDist;
		var query = PhysicsRayQueryParameters3D.Create(origin, end);

		var spaceState = GetWorld3D().DirectSpaceState;
		var result = spaceState.IntersectRay(query);

		float distance = maxDist;
		if (result.Count > 0) {
			var hitpoint = result["position"].AsVector3();
			distance = (hitpoint - origin).Length();
		}

		BulletPlane.GlobalPosition = RocketTubes.GlobalPosition;
		BulletPlane.GlobalRotation = RocketTubes.GlobalRotation;
		BulletPlane.Scale = new Vector3(1, 1, distance);
	}
}
