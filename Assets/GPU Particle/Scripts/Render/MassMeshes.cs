using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;

public class MassMeshes : MonoBehaviour
{
	static List<MassMeshData> DataList = new List<MassMeshData> ();

	static void GetMeshData (MassMeshes target)
	{
		MassMeshData data = null;
		foreach (var d in DataList)
			if (d.id == target.id)
				data = d;

		if (data == null) {
			target.CreateMesh ();
			data = new MassMeshData (target.id, target.mesh, target.numInSingleMesh);
			DataList.Add (data);
		} else {
			target.mesh = data.mesh;
			target.numInSingleMesh = data.numInSingleMesh;
		}
	}

	public int id = 0;
	public Mesh origin;
	public int numMeshes;
	public Material drawMat;
	public bool castShadow = true;
	public bool reserveShadow = true;
	public bool overrideMeshBounds;
	public Bounds bounds;
	
	Mesh mesh;
	int numInSingleMesh;
	int numDraw;

	// Use this for initialization
	void Start ()
	{
		GetMeshData (this);
		
		numDraw = numMeshes / numInSingleMesh;
		if (numDraw * numInSingleMesh < numMeshes)
			numDraw++;
	}

	void CreateMesh ()
	{
		var totalVerts = origin.vertexCount * numMeshes;
		numInSingleMesh = totalVerts <= 65000 ? numMeshes : 65000 / origin.vertexCount;

		mesh = new Mesh ();
		var vCount = numInSingleMesh * origin.vertexCount;
		var vertices = new Vector3[vCount];
		var normals = new Vector3[vCount];
		var uv = new Vector2[vCount];
		var uv2 = new Vector2[vCount];
		var oIndices = origin.GetIndices (0);
		var indices = new int[oIndices.Length * numInSingleMesh];

		for (var i = 0; i < numInSingleMesh; i++) {
			for (var j = 0; j < origin.vertexCount; j++) {
				var index = j + i * origin.vertexCount;
				vertices [index] = origin.vertices [j];
				normals [index] = origin.normals [j];
				uv [index] = origin.uv [j];
				uv2 [index] = new Vector2 ((float)i + 0.5f, 0.5f);
			}
			for (var j = 0; j < oIndices.Length; j++) {
				var index = j + i * oIndices.Length;
				indices [index] = oIndices [j] + i * origin.vertexCount;
			}
		}
		mesh.vertices = vertices;
		mesh.normals = normals;
		mesh.uv = uv;
		mesh.uv2 = uv2;
		mesh.SetIndices (indices, origin.GetTopology (0), 0);
		if (overrideMeshBounds)
			mesh.bounds = bounds;

		mesh.hideFlags = HideFlags.HideAndDontSave;
	}

	// Update is called once per frame
	void Update ()
	{
		for (var i = 0; i < numDraw; i++) {
			var mpBlock = Extensions.GetPropertyBlock ();
			mpBlock.SetFloat ("_Offset", i * numInSingleMesh);
			Graphics.DrawMesh (mesh, transform.position, transform.rotation, drawMat, gameObject.layer, null, 0, mpBlock, castShadow, reserveShadow);
		}
	}

	class MassMeshData
	{
		public MassMeshData (int i, Mesh m, int num)
		{
			id = i;
			mesh = m;
			numInSingleMesh = num;
		}

		public int id;
		public Mesh mesh;
		public int numInSingleMesh;
	}
}
