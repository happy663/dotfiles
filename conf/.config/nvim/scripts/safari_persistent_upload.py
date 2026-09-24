#!/usr/bin/env python3

import asyncio
import sys
import os
import argparse
import tempfile
import subprocess
import re
from playwright.async_api import async_playwright
from pathlib import Path


def get_clipboard_image():
    """クリップボードから画像を取得し、一時ファイルに保存"""
    with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp_file:
        tmp_path = tmp_file.name
    
    # pngpasteでクリップボードから画像を保存
    pngpaste_cmd = f"/opt/homebrew/opt/pngpaste/bin/pngpaste {tmp_path}"
    result = subprocess.run(pngpaste_cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        return tmp_path
    else:
        print("クリップボードに画像が見つかりません", file=sys.stderr)
        return None


def get_user_data_dir():
    """永続的なユーザーデータディレクトリを取得"""
    config_dir = Path.home() / ".config" / "nvim" / "safari-github-profile"
    config_dir.mkdir(parents=True, exist_ok=True)
    return str(config_dir)


async def setup_login_session(user_data_dir):
    """初回セットアップ: 手動ログイン用のセッション"""
    
    print("🔐 GitHub ログインセットアップ")
    print("=" * 50)
    print("Safariが起動します。以下の操作を行ってください:")
    print("1. GitHubにアクセス（自動で開きます）")
    print("2. ログイン（二段階認証含む）")
    print("3. ログイン完了後、Enter キーを押してください")
    print("=" * 50)
    
    async with async_playwright() as p:
        # 永続的なコンテキストでSafariを起動
        browser = await p.webkit.launch_persistent_context(
            user_data_dir=user_data_dir,
            headless=False,
            slow_mo=1000
        )
        
        # GitHubにアクセス
        page = browser.pages[0] if browser.pages else await browser.new_page()
        await page.goto('https://github.com')
        
        # ユーザーの操作を待機
        input("\n🎯 GitHubでログインを完了後、Enter キーを押してください...")
        
        # ログイン状態を確認
        await page.reload()
        await page.wait_for_load_state('networkidle')
        
        login_check = await page.locator("text=Sign in").count()
        if login_check > 0:
            print("❌ ログインが完了していません")
            await browser.close()
            return False
        else:
            print("✅ ログイン状態を確認しました")
            await browser.close()
            return True


async def upload_image_to_github_issue(image_path, issue_url, user_data_dir):
    """永続的なセッションでGitHubに画像をアップロード"""
    
    async with async_playwright() as p:
        try:
            # 永続的なコンテキストでSafariを起動（最高速度）
            browser = await p.webkit.launch_persistent_context(
                user_data_dir=user_data_dir,
                headless=False
                # slow_mo削除で最高速度化
            )
            
            # 新しいページを作成
            page = browser.pages[0] if browser.pages else await browser.new_page()
            
            # GitHub issueページに移動
            print(f"GitHub issueページに移動中: {issue_url}", file=sys.stderr)
            await page.goto(issue_url)
            
            # ページが完全に読み込まれるまで待機
            await page.wait_for_load_state('networkidle')
            
            # ページのタイトルとステータスを確認
            page_title = await page.title()
            print(f"ページタイトル: {page_title}", file=sys.stderr)
            
            # ログイン状態を確認
            login_check = await page.locator("text=Sign in").count()
            if login_check > 0:
                print("❌ ログインセッションが切れています", file=sys.stderr)
                print("   以下のコマンドで再ログインしてください:", file=sys.stderr)
                print(f"   python3 {__file__} --setup", file=sys.stderr)
                await browser.close()
                return None
            
            # アクセス権限エラーをチェック
            # より正確なエラー検出: 404エラーページの特定要素をチェック
            error_detected = False
            
            # 404エラーページの特徴的な要素をチェック
            error_selectors = [
                "h1:has-text('404')",
                "[data-view-component='true']:has-text('404')",
                ".blankslate:has-text('404')",
            ]
            
            for selector in error_selectors:
                try:
                    count = await page.locator(selector).count()
                    if count > 0:
                        error_detected = True
                        break
                except:
                    continue
            
            # その他のエラーメッセージを検索
            error_patterns = [
                "Page not found",
                "This is not the web page you are looking for",
                "Repository access blocked"
            ]
            
            for pattern in error_patterns:
                try:
                    count = await page.locator(f"text={pattern}").count()
                    if count > 0:
                        error_detected = True
                        break
                except:
                    continue
            
            # ページタイトルに"404"が含まれているかチェック
            if "404" in page_title.lower() or "not found" in page_title.lower():
                error_detected = True
            
            # エラーが見つかった場合
            if error_detected:
                print("❌ このリポジトリにアクセスする権限がありません", file=sys.stderr)
                print("   リポジトリが存在しないか、プライベートリポジトリへの権限が不足しています", file=sys.stderr)
                await browser.close()
                return None
            
            # コメント欄を探してクリック
            print("コメント欄を探しています...", file=sys.stderr)
            
            # 複数のセレクターを試行
            comment_selectors = [
                'textarea[placeholder*="comment" i]',
                'textarea#new_comment_field',
                'textarea[aria-label*="comment" i]',
                'textarea[name="comment[body]"]',
                '.js-comment-field',
                '#issue_comment_body'
            ]
            
            comment_textarea = None
            for selector in comment_selectors:
                try:
                    locator = page.locator(selector).first
                    if await locator.count() > 0:
                        comment_textarea = locator
                        print(f"コメント欄を発見: {selector}", file=sys.stderr)
                        break
                except:
                    continue
            
            if not comment_textarea:
                print("コメント欄が見つかりません", file=sys.stderr)
                await browser.close()
                return None
            
            # コメント欄をクリック
            await comment_textarea.click()
            
            # DOMが更新されるのを待つ
            await page.wait_for_timeout(500)
            
            # ファイル入力要素を探す
            print("ファイル入力要素を探しています...", file=sys.stderr)
            
            # まず、ページ上のすべてのfile inputを確認（デバッグ用）
            all_file_inputs = await page.locator('input[type="file"]').all()
            print(f"ページ上のfile input要素の数: {len(all_file_inputs)}", file=sys.stderr)
            
            file_input_selectors = [
                'input[type="file"]',
                'input[accept*="image"]',
                '.js-upload-input',
                'file-attachment input[type="file"]',
                '.js-upload-markdown-image'
            ]
            
            file_input = None
            for selector in file_input_selectors:
                try:
                    # visible/hiddenに関わらずすべて取得
                    all_inputs = await page.locator(selector).all()
                    print(f"セレクタ '{selector}' で見つかった要素数: {len(all_inputs)}", file=sys.stderr)
                    
                    if len(all_inputs) > 0:
                        file_input = page.locator(selector).first
                        print(f"ファイル入力要素を発見: {selector}", file=sys.stderr)
                        
                        # 要素の状態を確認
                        is_visible = await file_input.is_visible()
                        is_enabled = await file_input.is_enabled()
                        print(f"  - 可視性: {is_visible}, 有効性: {is_enabled}", file=sys.stderr)
                        break
                except Exception as e:
                    print(f"セレクタ '{selector}' でエラー: {e}", file=sys.stderr)
                    continue
            
            # file input要素が見つからない場合は、ドラッグ&ドロップでアップロードを試みる
            if not file_input:
                print("従来のfile input要素が見つかりません", file=sys.stderr)
                print("ドラッグ&ドロップ方式でアップロードを試みます...", file=sys.stderr)
                
                # 画像ファイルを読み込む
                print(f"画像をアップロード中: {image_path}", file=sys.stderr)
                
                # ファイルをBase64エンコード
                import base64
                with open(image_path, 'rb') as f:
                    file_content = f.read()
                    file_base64 = base64.b64encode(file_content).decode('utf-8')
                
                # ファイル名を取得
                file_name = os.path.basename(image_path)
                
                # DataTransferを使ってドラッグ&ドロップをシミュレート
                await page.evaluate(f"""
                    async ({{ base64Data, fileName }}) => {{
                        // Base64からBlobを作成
                        const byteCharacters = atob(base64Data);
                        const byteNumbers = new Array(byteCharacters.length);
                        for (let i = 0; i < byteCharacters.length; i++) {{
                            byteNumbers[i] = byteCharacters.charCodeAt(i);
                        }}
                        const byteArray = new Uint8Array(byteNumbers);
                        const blob = new Blob([byteArray], {{ type: 'image/png' }});
                        
                        // FileオブジェクトをBlobから作成
                        const file = new File([blob], fileName, {{ type: 'image/png' }});
                        
                        // DataTransferオブジェクトを作成
                        const dataTransfer = new DataTransfer();
                        dataTransfer.items.add(file);
                        
                        // テキストエリアを取得
                        const textarea = document.querySelector('textarea[placeholder*="comment" i]');
                        if (!textarea) {{
                            throw new Error('Textarea not found');
                        }}
                        
                        // drop イベントを発火
                        const dropEvent = new DragEvent('drop', {{
                            bubbles: true,
                            cancelable: true,
                            dataTransfer: dataTransfer
                        }});
                        
                        textarea.dispatchEvent(dropEvent);
                    }}
                """, {"base64Data": file_base64, "fileName": file_name})
            else:
                # ファイル入力要素が見つかった場合は従来の方法でアップロード
                print(f"画像をアップロード中: {image_path}", file=sys.stderr)
                await file_input.set_input_files(image_path)
            
            # アップロードプログレスを監視（超高速化）
            print("アップロード完了を待機中...", file=sys.stderr)
            
            # まず短時間で様子を見る（超高速化 + 早期検出）
            for wait_attempt in range(5):  # 0.5秒間、0.1秒ごとにチェック
                markdown_content = await comment_textarea.input_value()
                if markdown_content and (markdown_content.strip() != ""):
                    # 画像URLかHTMLタグが既に挿入されていないかチェック
                    markdown_match = re.search(r'!\[[Ii]mage\]\([^)]+\)', markdown_content)
                    html_match = re.search(r'<img[^>]*src="([^"]*)"[^>]*/?>', markdown_content)
                    if markdown_match or html_match:
                        # 既に完了している場合は即座に返す
                        print("早期検出: アップロード完了を確認", file=sys.stderr)
                        match = markdown_match or html_match
                        image_markdown = match.group(0)
                        print(image_markdown)
                        await browser.close()
                        return image_markdown
                    # 何かしら内容が挿入されたら次のステップへ
                    break
                await page.wait_for_timeout(100)
            
            # 追加で0.5秒待機（最小限の確認時間）
            await page.wait_for_timeout(500)
            
            # コメント欄でmarkdown形式の画像URLが挿入されるのを待機
            print("Markdown URL生成を待機中...", file=sys.stderr)
            
            # ポーリングでmarkdown URLの生成を待機（超高速化）
            for attempt in range(300):  # 300回試行（30秒間）: 大きい画像はGitHub側の処理に時間がかかる
                try:
                    # テキストエリアからmarkdown URLを取得
                    markdown_content = await comment_textarea.input_value()
                    
                    # ![image](...) または <img>タグを抽出
                    markdown_match = re.search(r'!\[[Ii]mage\]\([^)]+\)', markdown_content)
                    html_match = re.search(r'<img[^>]*src="([^"]*)"[^>]*/?>', markdown_content)
                    
                    match = markdown_match or html_match
                    
                    if match:
                        image_markdown = match.group(0)
                        print(image_markdown)
                        await browser.close()
                        return image_markdown
                    
                    # 0.1秒待機してから再試行（超高速化）
                    await page.wait_for_timeout(100)
                    
                except Exception as e:
                    print(f"試行 {attempt + 1}: エラー - {e}", file=sys.stderr)
                    await page.wait_for_timeout(100)
            
            # タイムアウト後の最終確認
            try:
                markdown_content = await comment_textarea.input_value()
                print(f"最終的なテキストエリアの内容: {markdown_content}", file=sys.stderr)
                
                markdown_match = re.search(r'!\[[Ii]mage\]\([^)]+\)', markdown_content)
                html_match = re.search(r'<img[^>]*src="([^"]*)"[^>]*/?>', markdown_content)
                match = markdown_match or html_match
                if match:
                    image_markdown = match.group(0)
                    print(image_markdown)
                    await browser.close()
                    return image_markdown
                else:
                    print("Markdown URL が見つかりませんでした", file=sys.stderr)
                    await browser.close()
                    return None
            except Exception as e:
                print(f"最終確認でエラー: {e}", file=sys.stderr)
                await browser.close()
                return None
                
        except Exception as e:
            print(f"アップロード中にエラーが発生しました: {e}", file=sys.stderr)
            return None


async def main():
    parser = argparse.ArgumentParser(description='永続セッションを使用したSafari GitHub画像アップロード')
    parser.add_argument('issue_url', nargs='?', help='GitHubのissue URL')
    parser.add_argument('--image', help='アップロードする画像ファイルのパス（指定しない場合はクリップボードから取得）')
    parser.add_argument('--setup', action='store_true', help='初回セットアップ: GitHubログインセッションを作成')
    
    args = parser.parse_args()
    
    # ユーザーデータディレクトリを取得
    user_data_dir = get_user_data_dir()
    
    # セットアップモード
    if args.setup:
        success = await setup_login_session(user_data_dir)
        if success:
            print("\n🎉 セットアップ完了！")
            print("これで画像アップロード機能が使用できます")
        else:
            print("\n❌ セットアップに失敗しました")
            sys.exit(1)
        return
    
    # issue_url が必要
    if not args.issue_url:
        print("エラー: issue_url が必要です", file=sys.stderr)
        print("使用方法:", file=sys.stderr)
        print(f"  {sys.argv[0]} https://github.com/owner/repo/issues/123", file=sys.stderr)
        print(f"  {sys.argv[0]} --setup  (初回セットアップ)", file=sys.stderr)
        sys.exit(1)
    
    # 画像を取得
    if args.image:
        image_path = args.image
        if not os.path.exists(image_path):
            print(f"画像ファイルが見つかりません: {image_path}", file=sys.stderr)
            sys.exit(1)
    else:
        image_path = get_clipboard_image()
        if not image_path:
            sys.exit(1)
    
    try:
        # アップロード実行
        result = await upload_image_to_github_issue(image_path, args.issue_url, user_data_dir)
        if not result:
            sys.exit(1)
    finally:
        # 一時ファイルを削除
        if not args.image and os.path.exists(image_path):
            os.unlink(image_path)


if __name__ == "__main__":
    asyncio.run(main())

