using UnityEngine;
using System.Collections;

public class RenderEffect : MonoBehaviour
{
	public string propName = "_PropName";
	public Material[] effects;
	public bool 
		show = true,
		blur = false;
	public float
		bSize = 1f;
	public int
		bItr = 3,
		bDS = 1,
		bHeight = 1080;
	public TextureWrapMode wrapMode;
	
	[SerializeField]
	RenderTexture
		output;
	RenderTexture[]
		rts = new RenderTexture[2];

	void Start ()
	{
		if (blur)
			bSize *= (float)Screen.height / (float)bHeight;
	}

	void Update ()
	{
		if (Input.GetKeyDown (KeyCode.Alpha6))
			show = !show;
	}

	void OnRenderImage (RenderTexture s, RenderTexture d)
	{
		CheckRTs (s);
		Graphics.Blit (s, rts [0]);
		foreach (var m in effects) {
			Graphics.Blit (rts [0], rts [1], m);
			SwapRTs ();
		}

		Graphics.Blit (rts [0], output);
		if (blur)
			output.GetBlur (bSize, bItr, bDS);
		Shader.SetGlobalTexture (propName, output);
		if (show)
			Graphics.Blit (output, d);
		else
			Graphics.Blit (s, d);
	}

	void CheckRTs (RenderTexture s)
	{
		if (rts [0] == null || rts [0].width != s.width || rts [0].height != s.height) {
			for (var i = 0; i < rts.Length; i++) {
				var rt = rts [i];
				rts [i] = Extensions.CreateRenderTexture (s, rt);
				rts [i].wrapMode = wrapMode;
			}
			output = Extensions.CreateRenderTexture (s, output);
			output.wrapMode = wrapMode;
		}
	}

	void SwapRTs ()
	{
		var tmp = rts [0];
		rts [0] = rts [1];
		rts [1] = tmp;
	}

	void OnDisabled ()
	{
		foreach (var rt in rts)
			Extensions.ReleaseRenderTexture (rt);
	}
}

