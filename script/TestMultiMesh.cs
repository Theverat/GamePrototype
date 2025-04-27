using Godot;
using System.Collections.Generic;
using System.Threading.Tasks;

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

    private enum Method
    {
        SINGLETHREAD,
        MULTITHREAD_1,
        MULTITHREAD_2,
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    public override void _Process(double delta) {
        ulong processStart = Time.GetTicksMsec();
        float elapsed = (processStart - startTime) / 1000f;

        List<Transform3D> transforms = [];

        // It seems that Multimesh.GetInstanceTransform() is not thread safe, so we have to make this expensive copy
        for (int i = 0; i < Multimesh.InstanceCount; i++) {
            transforms.Add(Multimesh.GetInstanceTransform(i));
        }

        static void update(int i, float elapsed, List<Transform3D> transforms) {
            int x = i % gridSize;
            int z = i / gridSize;

            //var transform = Multimesh.GetInstanceTransform(i);
            var transform = transforms[i];

            transform.Origin.Y = Mathf.Sin(x * 0.3f + elapsed) + Mathf.Cos(z * 0.6f + elapsed * 0.7f);
            transforms[i] = transform;

            //Multimesh.SetInstanceTransform(i, transform);
        }

        // -----------------------------------------------------
        var method = Method.SINGLETHREAD;

        if (method == Method.SINGLETHREAD) {
            for (int i = 0; i < Multimesh.InstanceCount; i++) {
                update(i, elapsed, transforms);
            }
        }
        else if (method == Method.MULTITHREAD_1) {
            Parallel.For(0, Multimesh.InstanceCount, i => {
                update(i, elapsed, transforms);
            });
        }
        else if (method == Method.MULTITHREAD_2) {
            var taskCount = 16;
            var tasks = new Task[taskCount];

            for (int taskNumber = 0; taskNumber < taskCount; taskNumber++) {
                // capturing taskNumber in lambda wouldn't work correctly
                int taskNumberCopy = taskNumber;

                tasks[taskNumber] = Task.Factory.StartNew(
                    () => {
                        for (int i = Multimesh.InstanceCount * taskNumberCopy / taskCount;
                            i < Multimesh.InstanceCount * (taskNumberCopy + 1) / taskCount;
                            i++) {
                            update(i, elapsed, transforms);
                        }
                    });
            }

            Task.WaitAll(tasks);
        }
        // -----------------------------------------------------

        // It seems that Multimesh.GetInstanceTransform() is not thread safe, so we have to make this expensive copy
        for (int i = 0; i < Multimesh.InstanceCount; i++) {
            Multimesh.SetInstanceTransform(i, transforms[i]);
        }

        GD.Print($"Instance Transform took {Time.GetTicksMsec() - processStart} ms");
    }
}
