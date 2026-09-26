#include <windows.h>
#include <tlhelp32.h>
#include <string.h>
//govnokod)))) s/o gemini
extern "C" __declspec(dllexport) int IsGameForeground(const char* exe_name) {
    if (!exe_name || !*exe_name) return 0;

    HWND fg = GetForegroundWindow();
    if (!fg) return 0;

    DWORD pid = 0;
    GetWindowThreadProcessId(fg, &pid);
    if (!pid) return 0;

    HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnap == INVALID_HANDLE_VALUE) return 0;

    PROCESSENTRY32W pe;
    pe.dwSize = sizeof(pe);
    int match = 0;

    if (Process32FirstW(hSnap, &pe)) {
        do {
            if (pe.th32ProcessID == pid) {
                char szExeA[MAX_PATH];
                WideCharToMultiByte(CP_UTF8, 0, pe.szExeFile, -1, szExeA, MAX_PATH, NULL, NULL);
                if (_stricmp(szExeA, exe_name) == 0) {
                    match = 1;
                }
                break;
            }
        } while (Process32NextW(hSnap, &pe));
    }

    CloseHandle(hSnap);
    return match;
}

extern "C" __declspec(dllexport) int GetForegroundProcessName(char* out_buf, int max_len) {
    if (!out_buf || max_len <= 0) return 0;
    out_buf[0] = '\0';

    HWND fg = GetForegroundWindow();
    if (!fg) return 0;

    DWORD pid = 0;
    GetWindowThreadProcessId(fg, &pid);
    if (!pid) return 0;

    HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnap == INVALID_HANDLE_VALUE) return 0;

    PROCESSENTRY32W pe;
    pe.dwSize = sizeof(pe);
    int found = 0;

    if (Process32FirstW(hSnap, &pe)) {
        do {
            if (pe.th32ProcessID == pid) {
                WideCharToMultiByte(CP_UTF8, 0, pe.szExeFile, -1, out_buf, max_len, NULL, NULL);
                found = 1;
                break;
            }
        } while (Process32NextW(hSnap, &pe));
    }

    CloseHandle(hSnap);
    return found;
}
