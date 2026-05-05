package com.esmahanim.rasajourney_app.unity

import android.content.Intent
import android.os.Bundle
import com.unity3d.player.UnityPlayerActivity

class UnityARActivity : UnityPlayerActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        if (intent != null) {
            setIntent(intent)
        }
    }
}
