package com.jigjigamarket.koolan

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    // When launchMode=singleTask, subsequent intents (e.g. the OAuth deep-link
    // callback from the browser) arrive here instead of onCreate(). Calling
    // setIntent() + super ensures the Flutter engine and plugins (including
    // supabase_flutter's app_links listener) receive the new URI so the auth
    // code can be exchanged for a session.
    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)
    }
}
