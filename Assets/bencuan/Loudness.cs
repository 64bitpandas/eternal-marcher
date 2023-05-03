 using UnityEngine;
 using UnityEngine.UI;
 using TMPro;
 
 public class Loudness : MonoBehaviour {
 
     public float updateStep = 0.1f;
     public int smooth = 10;
     public int sampleDataLength = 1024;
 
     private float currentUpdateTime = 0f;
 
     private float clipLoudness;
     private float _sum;
     private float[] _buffer;
     private int _index;


     private float[] clipSampleData;
     private float[] spectrum;
     private AudioSource audioSource;

     public TMP_Text loudnesstext;
     public MeshRenderer rend;
     
 
     // Use this for initialization
     void Start () {
        spectrum = new float[256];
        audioSource = gameObject.GetComponent<AudioSource>();
         if (!audioSource) {
             Debug.LogError(GetType() + ".Awake: there was no audioSource set.");
         }
         clipSampleData = new float[sampleDataLength];
         _buffer = new float[smooth];
     }
     
     // Update is called once per frame
     void Update () {

        // spectrum handling https://www.youtube.com/watch?v=t3kr_oBuGfo
        currentUpdateTime += Time.deltaTime;
        if (currentUpdateTime >= updateStep) {

            bool hit = false;
            AudioListener.GetSpectrumData(spectrum, 0, FFTWindow.Rectangular);
            for (int i = 0; i < spectrum.Length; i++) {
                float tmp = spectrum[i];

                if (tmp >= 30f) {
                    hit = true;
                }
            }
            
            if (hit) {
                Debug.Log("HIT");
            }

            currentUpdateTime = 0f;
            audioSource.clip.GetData(clipSampleData, audioSource.timeSamples); //I read 1024 samples, which is about 80 ms on a 44khz stereo clip, beginning at the current sample position of the clip.
            clipLoudness = 0f;
            foreach (var sample in clipSampleData) {
                clipLoudness += Mathf.Abs(sample);
            }
            clipLoudness /= sampleDataLength; //clipLoudness is what you are looking for
            loudnesstext.text = "" + clipLoudness;

            // rolling avg
            _sum = _sum - _buffer[_index] + clipLoudness;
            _buffer[_index] = clipLoudness;
            _index = (_index + 1) % smooth;

            rend.material.SetFloat("_Level", _sum / smooth);
        }
 
     }
 
 }
 