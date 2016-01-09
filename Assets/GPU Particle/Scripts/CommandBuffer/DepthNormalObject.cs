using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

public class DepthNormalObject : MonoBehaviour
{
	public Material depthDrawer;

	Renderer r {
		get {
			if (_r == null)
				_r = GetComponent<Renderer> ();
			return _r;
		}
	}

	Renderer _r;

	public void DrawBack (CommandBuffer cb)
	{
		cb.DrawRenderer (r, depthDrawer, 0, 0);
	}

	public void DrawFront (CommandBuffer cb)
	{
		cb.DrawRenderer (r, depthDrawer, 0, 1);
	}
}
