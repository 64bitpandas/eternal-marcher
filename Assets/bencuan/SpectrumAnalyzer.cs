using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SpectrumAnalyzer : MonoBehaviour
{
    AudioSource audioSource;
    public static float[] samples = new float[512];

    public static float[] freqBand = new float[8];
    float[] freqBandHighest = new float[8];
    public static float[] audioBands = new float[8];

    public MeshRenderer rend;
    public List<RectTransform> bars;

    void CreateAudioBands() {
        // This function should first update freqBandHighest, which contains the highest-yet-seen values for each bin. 
        // Then it divides each current band value by the highest-yet-seen to get us a number between 0 and 1. This result is saved to array audioBands.
        for (int i = 0; i < 8; i++) {
            if (freqBand[i] > freqBandHighest[i]) {
                freqBandHighest[i] = freqBand[i];
            }
        }

        float total = 0f;
        for (int i = 0; i < 8; i++) {
            audioBands[i] = Mathf.Lerp(audioBands[i], freqBand[i] / freqBandHighest[i], 0.8f);
            bars[i].transform.localScale = new Vector3(0.5f, audioBands[i]*1.5f, 0.5f);
            total += audioBands[i];
        }

        for (int i = 0; i < 8; i++) {
            bars[i].GetComponent<RawImage>().color = Color.Lerp(Color.green, Color.white, total/8);
        }

        rend.material.SetFloatArray("_FreqBands", audioBands);
    }

    void MakeFrequencyBands() {
        int count = 0;
        
        // Iterate through the 8 bins.
        for (int i = 0; i < 8; i++)  {
            float average = 0;
            int sampleCount = (int)Mathf.Pow (2, i + 1);

            // Adding the remaining two samples into the last bin.
            if (i == 7) {
                sampleCount += 2;
            }

            // Go through the number of samples for each bin, add the data to the average
            for (int j = 0; j < sampleCount; j++) {
                average += samples [count];
                count++;
            }

            // Divide to create the average, and scale it appropriately.
            average /= count;
            freqBand[i] = (i+1) * 100 * average;
        }
    }

    
// Start is called before the first frame update
    void Start()
    {
        audioSource = GetComponent<AudioSource>();
    }

    void GetSpectrumAudioSource() {
        audioSource.GetSpectrumData(samples, 0, FFTWindow.Blackman);
    }   

    // Update is called once per frame
    void Update()
    {
        GetSpectrumAudioSource();
        MakeFrequencyBands();
        CreateAudioBands();
    }
}