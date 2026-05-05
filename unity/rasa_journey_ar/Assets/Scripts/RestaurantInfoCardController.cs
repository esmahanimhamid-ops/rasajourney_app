using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class RestaurantInfoCardController : MonoBehaviour
{
    [Header("Text")]
    [SerializeField] private TMP_Text restaurantNameText;
    [SerializeField] private TMP_Text cuisineLabelText;
    [SerializeField] private TMP_Text statusText;
    [SerializeField] private TMP_Text hoursText;
    [SerializeField] private TMP_Text ratingText;
    [SerializeField] private TMP_Text subtitleText;

    [Header("Status Styling")]
    [SerializeField] private Image statusBackground;
    [SerializeField] private Color openColor = new(0.22f, 0.65f, 0.32f, 0.92f);
    [SerializeField] private Color closedColor = new(0.86f, 0.25f, 0.21f, 0.92f);
    [SerializeField] private Color neutralColor = new(0.94f, 0.55f, 0.16f, 0.92f);

    public void ApplyPayload(RestaurantCardPayload payload)
    {
        if (payload == null)
        {
            payload = RestaurantCardPayload.Demo();
        }

        SetText(restaurantNameText, payload.restaurantName);
        SetText(cuisineLabelText, payload.cuisineLabel);
        SetText(statusText, payload.status);
        SetText(hoursText, payload.hours);
        SetText(ratingText, payload.rating);
        SetText(subtitleText, payload.subtitle);
        ApplyStatusColor(payload.status);
    }

    public void CloseExperience()
    {
        FlutterUnityBridge.UnloadToHost();
    }

    private void SetText(TMP_Text label, string value)
    {
        if (label != null)
        {
            label.text = value;
        }
    }

    private void ApplyStatusColor(string status)
    {
        if (statusBackground == null)
        {
            return;
        }

        var normalized = (status ?? string.Empty).Trim().ToLowerInvariant();

        if (normalized.Contains("open"))
        {
            statusBackground.color = openColor;
            return;
        }

        if (normalized.Contains("closed"))
        {
            statusBackground.color = closedColor;
            return;
        }

        statusBackground.color = neutralColor;
    }
}
