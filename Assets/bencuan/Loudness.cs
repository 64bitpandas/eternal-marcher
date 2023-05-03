 using UnityEngine;
 using UnityEngine.UI;
 using TMPro;
 using System.Collections;
 
 public class Loudness : MonoBehaviour {
 
     public float updateStep = 0.1f;
     public int smooth = 15;
     public int sampleDataLength = 1024;
 
     private float currentUpdateTime = 0f;
 
     private float clipLoudness;
     private float _sum;
     private float[] _buffer;
     private int _index;


     private float[] clipSampleData;
     private float[] spectrum;
     private AudioSource audioSource;

     public MeshRenderer rend;

     private Color[] colors;
     private int currCol;

     public RawImage flashImg;


     IEnumerator Flash (float t) {
        Color col = Color.white;
        for (float alpha = 1f; alpha >= 0; alpha -= 0.05f) {
            col.a = alpha;
            flashImg.color = col;
            yield return new WaitForSeconds(t / 20);
        }
     } 
 
     // Use this for initialization
     void Start () {
        currCol = -1;
        spectrum = new float[256];
        audioSource = gameObject.GetComponent<AudioSource>();
         if (!audioSource) {
             Debug.LogError(GetType() + ".Awake: there was no audioSource set.");
         }
         clipSampleData = new float[sampleDataLength];
         _buffer = new float[smooth];

         colors = new Color[5];
         colors[0] = new Color(23/256f, 184/256f, 144/256f);
         colors[1] = new Color(141/256f, 148/256f, 186/256f);
         colors[2] = new Color(237/256f, 106/256f, 94/256f);
         colors[3]= new Color(255/256f, 230/256f, 109/256f);
         colors[4] = new Color(77/256f, 108/256f, 250/256f);
     }
     
     // Update is called once per frame
     void Update () {

        // spectrum handling https://www.youtube.com/watch?v=t3kr_oBuGfo
        currentUpdateTime += Time.deltaTime;
        if (currentUpdateTime >= updateStep) {

            bool hit = false;
            AudioListener.GetSpectrumData(spectrum, 0, FFTWindow.Rectangular);
            

            currentUpdateTime = 0f;
            audioSource.clip.GetData(clipSampleData, audioSource.timeSamples); //I read 1024 samples, which is about 80 ms on a 44khz stereo clip, beginning at the current sample position of the clip.
            clipLoudness = 0f;
            foreach (var sample in clipSampleData) {
                clipLoudness += Mathf.Abs(sample);
            }
            clipLoudness /= sampleDataLength; //clipLoudness is what you are looking for

            // rolling avg
            _sum = _sum - _buffer[_index] + clipLoudness;
            _buffer[_index] = clipLoudness;
            _index = (_index + 1) % smooth;

            rend.material.SetFloat("_Level", _sum / smooth);


        }

        if (Input.GetKeyDown("space")) {

            int rng = Random.Range(0, 5);

            if (rng == currCol) {
                rng = (rng + 1) % 5;
            }

            currCol = rng;

            rend.material.SetColor("_Color", colors[rng]);
            rend.material.SetFloat("_Rand", Random.Range(0, 5));
            StartCoroutine(Flash(0.5f));
        }
 
     }
 
 }
 