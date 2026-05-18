package com.dreamcast.app

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val pipChannelName = "dream_cast/player_pip"
    private var pipChannel: MethodChannel? = null
    private var pipEnabled = false
    private var pipAspectRatio = Rational(16, 9)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pipChannelName)
        pipChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(isPipSupported())
                "setEnabled" -> {
                    pipEnabled = call.argument<Boolean>("enabled") == true
                    pipAspectRatio = safeAspectRatio(
                        call.argument<Int>("width") ?: 16,
                        call.argument<Int>("height") ?: 9,
                    )
                    updatePictureInPictureParams()
                    result.success(null)
                }
                "enter" -> result.success(enterPipIfPossible())
                else -> result.notImplemented()
            }
        }
    }

    override fun onUserLeaveHint() {
        if (enterPipIfPossible()) return
        super.onUserLeaveHint()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod(
            "changed",
            mapOf("active" to isInPictureInPictureMode),
        )
    }

    private fun enterPipIfPossible(): Boolean {
        if (!pipEnabled || !isPipSupported()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isInPictureInPictureMode) {
            return false
        }
        return try {
            enterPictureInPictureMode(buildPictureInPictureParams())
        } catch (_: IllegalStateException) {
            false
        } catch (_: IllegalArgumentException) {
            false
        }
    }

    private fun isPipSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    private fun updatePictureInPictureParams() {
        if (!isPipSupported()) return
        try {
            setPictureInPictureParams(buildPictureInPictureParams())
        } catch (_: IllegalArgumentException) {
            pipAspectRatio = Rational(16, 9)
            setPictureInPictureParams(buildPictureInPictureParams())
        }
    }

    private fun buildPictureInPictureParams(): PictureInPictureParams {
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(pipAspectRatio)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(pipEnabled)
        }
        return builder.build()
    }

    private fun safeAspectRatio(width: Int, height: Int): Rational {
        if (width <= 0 || height <= 0) return Rational(16, 9)
        val ratio = width.toDouble() / height.toDouble()
        return when {
            ratio < 0.42 -> Rational(100, 239)
            ratio > 2.39 -> Rational(239, 100)
            else -> Rational(width, height)
        }
    }
}
