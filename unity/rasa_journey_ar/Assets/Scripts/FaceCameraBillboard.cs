using UnityEngine;

public class FaceCameraBillboard : MonoBehaviour
{
    [SerializeField] private bool keepVertical = true;

    private Transform _cameraTransform;

    private void LateUpdate()
    {
        if (_cameraTransform == null && Camera.main != null)
        {
            _cameraTransform = Camera.main.transform;
        }

        if (_cameraTransform == null)
        {
            return;
        }

        var direction = transform.position - _cameraTransform.position;

        if (keepVertical)
        {
            direction.y = 0f;
        }

        if (direction.sqrMagnitude < 0.001f)
        {
            return;
        }

        transform.rotation = Quaternion.LookRotation(direction.normalized, Vector3.up);
    }
}
