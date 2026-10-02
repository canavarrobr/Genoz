package br.genoz.genoz

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

// FlutterFragmentActivity: exigida pela biometria (local_auth).
class MainActivity : FlutterFragmentActivity() {
    private val saveRequest = 4207
    private var pendingSave: Pair<String, MethodChannel.Result>? = null
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Proteção de tela: bloqueia capturas e esconde o conteúdo nos apps recentes.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "genoz/janela").setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // "Salvar como" do sistema copiando o arquivo em fluxo (arquivos grandes não
        // passam pela memória). Nada sai do aparelho: o destino é escolhido pelo usuário.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "genoz/arquivos").setMethodCallHandler { call, result ->
            when (call.method) {
                "salvar" -> {
                    val path = call.argument<String>("caminho")
                    val name = call.argument<String>("nome")
                    val mime = call.argument<String>("tipo") ?: "application/octet-stream"
                    if (path == null || name == null || pendingSave != null) {
                        result.error("argumentos", "caminho e nome são obrigatórios", null)
                        return@setMethodCallHandler
                    }
                    pendingSave = Pair(path, result)
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = mime
                        putExtra(Intent.EXTRA_TITLE, name)
                    }
                    startActivityForResult(intent, saveRequest)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("API de resultado clássica: suficiente para um único pedido por vez")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveRequest) return
        val (path, result) = pendingSave ?: return
        pendingSave = null
        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(false)
            return
        }
        io.execute {
            try {
                contentResolver.openOutputStream(uri, "w").use { out ->
                    File(path).inputStream().use { input -> input.copyTo(out!!, 1 shl 16) }
                }
                main.post { result.success(true) }
            } catch (e: Exception) {
                main.post { result.error("gravar", e.message, null) }
            }
        }
    }
}
