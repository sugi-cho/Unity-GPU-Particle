using UnityEngine;
using System.Collections;

public class EmitParticle : MonoBehaviour
{
	public MultiRenderTexture targetRender;
	public Material emitMat;
	public float emitDepth = 2f;
	public float emitRadius = 1f;
	public float lifeTime = 5f;
	public float emitRate = 100f;
	public Color emitColor;
	public Vector4 initialVel;
	
	// Update is called once per frame
	void Update ()
	{
		if (!Input.GetMouseButton (0))
			return;
		var pos = Input.mousePosition;
		pos.z = emitDepth;
		pos = Camera.main.ScreenToWorldPoint (pos);

		emitMat.SetVector ("_EPoint", new Vector4 (pos.x, pos.y, pos.z, emitRadius));
		emitMat.SetVector ("_Vel0", initialVel);
		emitMat.SetFloat ("_Emission", emitRate);
		emitMat.SetColor ("_Color", emitColor);
		emitMat.SetFloat ("_Life", lifeTime);

		targetRender.Render (0, emitMat);
	}
}
