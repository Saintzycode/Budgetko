package com.example.budgetko

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "budgetko/downloads"
    private val pickRequestCode = 7341
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveWorkbook" -> handleSave(call, result)
                "pickBackupFile" -> handlePick(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleSave(call: MethodCall, result: MethodChannel.Result) {
        val fileName = call.argument<String>("fileName")
        val content = call.argument<String>("content")
        if (fileName.isNullOrBlank() || content == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "fileName and content are required",
                null
            )
            return
        }
        val mimeType = call.argument<String>("mimeType")
            ?: "application/vnd.ms-excel"

        try {
            result.success(saveToDownloads(fileName, content, mimeType))
        } catch (error: Exception) {
            result.error(
                "DOWNLOAD_SAVE_FAILED",
                error.message,
                null
            )
        }
    }

    private fun handlePick(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error(
                "PICK_IN_PROGRESS",
                "A file selection is already open",
                null
            )
            return
        }
        pendingPick = result
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                putExtra(
                    Intent.EXTRA_MIME_TYPES,
                    arrayOf(
                        "application/json",
                        "text/plain",
                        "application/octet-stream"
                    )
                )
            }
            startActivityForResult(intent, pickRequestCode)
        } catch (error: Exception) {
            pendingPick = null
            result.error("FILE_PICK_FAILED", error.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequestCode) {
            return
        }

        val result = pendingPick
        pendingPick = null
        if (result == null) {
            return
        }

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }

        try {
            val content = contentResolver.openInputStream(uri)
                ?.bufferedReader()
                ?.use { it.readText() }
            if (content == null) {
                result.error(
                    "FILE_READ_FAILED",
                    "Could not read the selected file",
                    null
                )
            } else {
                result.success(content)
            }
        } catch (error: Exception) {
            result.error("FILE_READ_FAILED", error.message, null)
        }
    }

    private fun saveToDownloads(
        fileName: String,
        content: String,
        mimeType: String
    ): String {
        val folderName = "BudgetKo exports"
        val bytes = content.toByteArray(Charsets.UTF_8)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/$folderName"
                )
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = resolver.insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                values
            ) ?: throw IllegalStateException("Could not create download file")

            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
            } ?: throw IllegalStateException("Could not open download file")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            return "Downloads/$folderName/$fileName"
        }

        @Suppress("DEPRECATION")
        val downloads = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        val directory = File(downloads, folderName)
        if (!directory.exists()) {
            directory.mkdirs()
        }

        val file = File(directory, fileName)
        FileOutputStream(file).use { stream ->
            stream.write(bytes)
        }
        return file.absolutePath
    }
}
