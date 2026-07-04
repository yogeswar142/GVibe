# Antigravity & Gemini Project Rules & Guidelines

To maximize developer efficiency and minimize token usage, the following rules and guidelines should be strictly adhered to by all developers and AI agents working on the GVibe codebase.

---

## 🪙 Token Optimization Rules

1. **Incremental Edits**: Never replace the whole file if you are only changing a few lines. Use the most specific replacement tools (`replace_file_content` or `multi_replace_file_content`) to target exact lines.
2. **Selective Reading**: Do not read large directories or files recursively unless absolutely necessary. Read specific files within specific line ranges (`StartLine` and `EndLine` in `view_file`).
3. **No Redundant Tasks**: Before running any background commands, check if the process is already running using `pgrep` or `ps` to avoid multiple duplicate background services.
4. **Console Output Management**: When running command line tools (e.g. `flutter run`, `npm install`), filter logs using `grep` or `head` to avoid dumping thousands of lines of output into the LLM context.
5. **No Placeholders**: Always write production-ready code with complete logic to avoid iterative correction runs.

---

## 🛠️ GVibe Development Architecture

### Backend (Node.js & Express)
* **REST Structure**: Keep routes modularized under `routes/` and business logic separated inside `controllers/`.
* **Database Models**: Extend MongoDB schemas explicitly. Always clean up temporary collections or documents with TTL indexes (e.g. temporary profile creation records).
* **Domain Validation**: Restrict student registration specifically to the `@student.gitam.edu` email domain.

### Frontend (Flutter & Riverpod)
* **State Management**: Use `flutter_riverpod` or state providers to manage state cleanly.
* **Component Reuse**: Maintain widgets in `lib/shared/widgets/` to avoid duplicating layout code.
* **No Unused Imports / Parameters**: Keep code clean. Avoid unused variables or imports to minimize compilation warning clutter.
* **Responsive Layouts & Overflow Prevention**: To prevent RenderFlex overflow errors (yellow-and-black striped boxes) on smaller screens, always wrap dynamic text and flexible widgets inside `Row` or `Column` with `Expanded` or `Flexible` and configure `overflow: TextOverflow.ellipsis` and `maxLines` where applicable.

---

## 📱 Wireless Debugging & Test Environment
* **Device**: OnePlus CPH2613 (Android 16, SDK 36)
* **ADB Wireless Configuration**: `192.168.1.5:37707`
* **Release Builds**: No release APK compilation required for online LambdaTest. All tests are conducted live on the physical device over wireless ADB.
* **Backend Dev Endpoint**: Bound to static ngrok domain `https://levitative-unpresumptuously-claire.ngrok-free.dev`.
