using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SongSelect : MonoBehaviour
{

    private AudioSource ad;
    public List<AudioClip> songs;
    public int curr;

    // Start is called before the first frame update
    void Start() {
        ad = GetComponent<AudioSource>();
        curr = 0;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.LeftArrow)) {
            curr = (curr - 1) % songs.Count;
            ChooseSong();
        } else if (Input.GetKeyDown(KeyCode.RightArrow)) { 
            curr = (curr + 1) % songs.Count;
            ChooseSong();
        }
    }

    void ChooseSong() {
        ad.clip = songs[curr];
        ad.Play(0);
    }
}
