using TMPro;
using UnityEngine;

public class RestaurantInfoCardController : MonoBehaviour
{
    public TextMeshProUGUI nameText;
    public TextMeshProUGUI cuisineText;
    public TextMeshProUGUI ratingText;

    public void SetData(string name, string cuisine, string rating)
    {
        nameText.text = name;
        cuisineText.text = cuisine;
        ratingText.text = rating;
    }
}