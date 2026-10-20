package io.grovs.wrapper

import com.google.firebase.messaging.FirebaseMessaging

// Firebase is optional for the host app, so its classes may be missing at runtime.
internal object FirebaseTokenFetcher {
    fun fetch(onToken: (String) -> Unit) {
        try {
            Class.forName("com.google.firebase.messaging.FirebaseMessaging")
        } catch (e: ClassNotFoundException) {
            return
        }
        try {
            FirebaseMessaging.getInstance().token.addOnSuccessListener { onToken(it) }
        } catch (e: IllegalStateException) {
            // Firebase is on the classpath but not initialised.
        }
    }
}
