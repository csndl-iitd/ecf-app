package com.example.event_tracker

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

class ScrollAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED) {
            val scrollDeltaX = event.scrollDeltaX
            val scrollDeltaY = event.scrollDeltaY
            Log.d("ScrollAccessibilityService", "Scroll delta ( X: $scrollDeltaX , Y: $scrollDeltaY ) ")



            Toast.makeText(this, "Scroll detected ( $scrollDeltaX , $scrollDeltaY )" , Toast.LENGTH_SHORT).show()
        }
    }

    override fun onInterrupt() {
        // Handle interruptions if necessary
    }
}
