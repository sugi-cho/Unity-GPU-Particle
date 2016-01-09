using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

public class DepthNormalRenderer : MonoBehaviour
{
	CommandBuffer commands;

	// Use this for initialization
	void Start ()
	{
		commands = CreateCommandBuffer ();
		Camera.main.AddCommandBuffer (CameraEvent.BeforeGBuffer, commands);
	}
	
	// Update is called once per frame
	void Update ()
	{
	
	}

	CommandBuffer CreateCommandBuffer ()
	{
		var cb = new CommandBuffer ();
		cb.name = "DrawDepthCmd";
		UpdateCommandBuffer (cb);
		return cb;
	}

	void UpdateCommandBuffer (CommandBuffer cb)
	{
		var id_back = Shader.PropertyToID ("BackTex");
		var id_front = Shader.PropertyToID ("FrontTex");

		cb.GetTemporaryRT (id_back, -1, -1, 0, FilterMode.Point, RenderTextureFormat.ARGBFloat);
		cb.SetRenderTarget (id_back);
		cb.ClearRenderTarget (true, true, Color.black);
		foreach (var obj in FindObjectsOfType<DepthNormalObject>())
			obj.DrawBack (cb);
		cb.SetGlobalTexture ("_DepthNormalBack", id_back);

		cb.GetTemporaryRT (id_front, -1, -1, 0, FilterMode.Point, RenderTextureFormat.ARGBFloat);
		cb.SetRenderTarget (id_front);
		cb.ClearRenderTarget (true, true, Color.black);
		foreach (var obj in FindObjectsOfType<DepthNormalObject>())
			obj.DrawFront (cb);
		cb.SetGlobalTexture ("_DepthNormalFront", id_front);

	}
}
