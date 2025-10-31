import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

/// Google認証サービス
class GoogleAuthService {
  // Google Sign-Inのインスタンス（Google Sheets & Drive APIのスコープ付き）
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      sheets.SheetsApi.spreadsheetsScope, // Spreadsheetの読み書き権限
      drive.DriveApi.driveScope, // Drive全体へのアクセス権限（既存フォルダへのアクセスに必要）
    ],
  );

  /// 現在サインインしているGoogleアカウントを取得
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// サインインしているかどうか
  static bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Googleアカウントでサインイン
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      print('Google Sign-In エラー: $e');
      return null;
    }
  }

  /// サインアウト
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Google Sign-Out エラー: $e');
    }
  }

  /// サインインしているか確認し、サインインしていない場合はサインインを促す
  static Future<GoogleSignInAccount?> ensureSignedIn() async {
    if (isSignedIn) {
      return currentUser;
    }
    return await signIn();
  }

  /// 認証済みHTTPクライアントを取得（Google APIs用）
  static Future<auth.AuthClient?> getAuthenticatedClient() async {
    try {
      final account = await ensureSignedIn();
      if (account == null) return null;

      // GoogleSignInをGoogleAPIs authに変換
      final authClient = await _googleSignIn.authenticatedClient();
      return authClient;
    } catch (e) {
      print('認証クライアント取得エラー: $e');
      return null;
    }
  }

  /// Sheets APIインスタンスを取得
  static Future<sheets.SheetsApi?> getSheetsApi() async {
    final client = await getAuthenticatedClient();
    if (client == null) return null;

    return sheets.SheetsApi(client);
  }

  /// Drive APIインスタンスを取得
  static Future<drive.DriveApi?> getDriveApi() async {
    final client = await getAuthenticatedClient();
    if (client == null) return null;

    return drive.DriveApi(client);
  }
}
