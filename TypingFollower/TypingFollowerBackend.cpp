#include "TypingFollowerBackend.h"

#include <QCoreApplication>
#include <QThread>
#include <QDebug>

#ifdef Q_OS_WIN
#include <windows.h>

static HHOOK s_keyboardHook = nullptr;
static HHOOK s_mouseHook = nullptr;
static QList<TypingFollowerBackend*> s_activeInstances;
static int s_hookRefCount = 0;

static QString mouseButtonName(int button)
{
    switch (button) {
    case 1: return "LMB";
    case 2: return "RMB";
    case 3: return "MMB";
    case 4: return "ThumbUp";
    case 5: return "ThumbDown";
    default: return QString();
    }
}

static QString currentModifiers()
{
    QStringList parts;
    if (GetAsyncKeyState(VK_SHIFT) & 0x8000) parts << "Shift";
    if (GetAsyncKeyState(VK_CONTROL) & 0x8000) parts << "Ctrl";
    if (GetAsyncKeyState(VK_MENU) & 0x8000) parts << "Alt";
    if (GetAsyncKeyState(VK_LWIN) & 0x8000 || GetAsyncKeyState(VK_RWIN) & 0x8000) parts << "Win";
    return parts.join("+");
}

static QString buildKeyName(TypingFollowerBackend *instance, quint32 vkey)
{
    QStringList parts;
    QString mods = currentModifiers();
    if (!mods.isEmpty())
        parts << mods;

    QString keyName = instance->keyTextFromVKey(vkey);
    if (!keyName.isEmpty())
        parts << keyName;

    return parts.join("+");
}

static QString buildMouseButtonName(int button)
{
    QStringList parts;
    QString mods = currentModifiers();
    if (!mods.isEmpty())
        parts << mods;

    QString name = mouseButtonName(button);
    if (!name.isEmpty())
        parts << name;

    return parts.join("+");
}

static LRESULT CALLBACK keyboardProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    if (nCode >= 0) {
        KBDLLHOOKSTRUCT *kb = (KBDLLHOOKSTRUCT *)lParam;
        quint32 vkey = kb->vkCode;

        for (auto *inst : s_activeInstances) {
            QString keyName = inst->keyTextFromVKey(vkey);
            if (keyName.isEmpty()) continue;

            if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
                if (!inst->hasPressedKey(vkey)) {
                    QString displayName = buildKeyName(inst, vkey);
                    inst->setPressedKey(vkey, displayName);
                    emit inst->keyPressed(displayName);
                }
            } else if (wParam == WM_KEYUP || wParam == WM_SYSKEYUP) {
                if (inst->hasPressedKey(vkey)) {
                    QString displayName = inst->pressedKeyName(vkey);
                    inst->removePressedKey(vkey);
                    emit inst->keyReleased(displayName);
                }
            }
        }
    }
    return CallNextHookEx(s_keyboardHook, nCode, wParam, lParam);
}

static LRESULT CALLBACK mouseProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    if (nCode >= 0) {
        int button = 0;
        bool isDown = false;
        bool isUp = false;

        switch (wParam) {
        case WM_LBUTTONDOWN: button = 1; isDown = true; break;
        case WM_LBUTTONUP: button = 1; isUp = true; break;
        case WM_RBUTTONDOWN: button = 2; isDown = true; break;
        case WM_RBUTTONUP: button = 2; isUp = true; break;
        case WM_MBUTTONDOWN: button = 3; isDown = true; break;
        case WM_MBUTTONUP: button = 3; isUp = true; break;
        case WM_XBUTTONDOWN: button = GET_XBUTTON_WPARAM(wParam); isDown = true; break;
        case WM_XBUTTONUP: button = GET_XBUTTON_WPARAM(wParam); isUp = true; break;
        default: break;
        }

        if (button >= 1 && button <= 5) {
            for (auto *inst : s_activeInstances) {
                if (!inst->listenMouse()) continue;
                if (isDown && !inst->hasPressedButton(button)) {
                    QString displayName = buildMouseButtonName(button);
                    inst->setPressedButton(button, displayName);
                    emit inst->mousePressed(displayName);
                } else if (isUp && inst->hasPressedButton(button)) {
                    QString displayName = inst->pressedButtonName(button);
                    inst->removePressedButton(button);
                    emit inst->mouseReleased(displayName);
                }
            }
        }
    }
    return CallNextHookEx(s_mouseHook, nCode, wParam, lParam);
}
#endif

#ifdef Q_OS_LINUX
#include <xcb/xcb.h>
#include <xcb/xinput.h>
#include <xcb/xcb_keysyms.h>
#include <QSocketNotifier>

struct XInputContext {
    xcb_connection_t *conn = nullptr;
    xcb_window_t root = 0;
    int event_base = 0;
    int opcode = 0;
    bool valid = false;
};

static XInputContext s_xiContext;
static QList<TypingFollowerBackend*> s_activeInstances;
static QSocketNotifier *s_notifier = nullptr;
static int s_hookRefCount = 0;

static QString buttonNameLinux(int button)
{
    switch (button) {
    case 1: return "LMB";
    case 2: return "RMB";
    case 3: return "MMB";
    case 4: return "ThumbUp";
    case 5: return "ThumbDown";
    default: return QString();
    }
}

static QString keyTextFromXcbKeycode(xcb_keysyms_t *syms, xcb_keycode_t keycode)
{
    QString keyName;
    xcb_keysym_t sym = xcb_keysym_lookup(syms, keycode);

    if (sym >= XCB_KEYSYM_A && sym <= XCB_KEYSYM_Z) {
        keyName = QChar('A' + (sym - XCB_KEYSYM_A));
    } else if (sym >= XCB_KEYSYM_0 && sym <= XCB_KEYSYM_9) {
        keyName = QChar('0' + (sym - XCB_KEYSYM_0));
    } else if (sym >= XCB_KEYSYM_F1 && sym <= XCB_KEYSYM_F24) {
        keyName = "F" + QString::number(sym - XCB_KEYSYM_F1 + 1);
    } else {
        switch (sym) {
        case XCB_KEYSYM_space: keyName = "Space"; break;
        case XCB_KEYSYM_Return: keyName = "Enter"; break;
        case XCB_KEYSYM_Escape: keyName = "Escape"; break;
        case XCB_KEYSYM_Tab: keyName = "Tab"; break;
        case XCB_KEYSYM_BackSpace: keyName = "Backspace"; break;
        case XCB_KEYSYM_Left: keyName = "Left"; break;
        case XCB_KEYSYM_Right: keyName = "Right"; break;
        case XCB_KEYSYM_Up: keyName = "Up"; break;
        case XCB_KEYSYM_Down: keyName = "Down"; break;
        case XCB_KEYSYM_Shift_L:
        case XCB_KEYSYM_Shift_R: keyName = "Shift"; break;
        case XCB_KEYSYM_Control_L:
        case XCB_KEYSYM_Control_R: keyName = "Ctrl"; break;
        case XCB_KEYSYM_Alt_L:
        case XCB_KEYSYM_Alt_R: keyName = "Alt"; break;
        case XCB_KEYSYM_Caps_Lock: keyName = "CapsLock"; break;
        case XCB_KEYSYM_Delete: keyName = "Delete"; break;
        case XCB_KEYSYM_Insert: keyName = "Insert"; break;
        case XCB_KEYSYM_Home: keyName = "Home"; break;
        case XCB_KEYSYM_End: keyName = "End"; break;
        case XCB_KEYSYM_Page_Up: keyName = "PageUp"; break;
        case XCB_KEYSYM_Page_Down: keyName = "PageDown"; break;
        case XCB_KEYSYM_plus: keyName = "+"; break;
        case XCB_KEYSYM_minus: keyName = "-"; break;
        case XCB_KEYSYM_equal: keyName = "="; break;
        case XCB_KEYSYM_comma: keyName = ","; break;
        case XCB_KEYSYM_period: keyName = "."; break;
        case XCB_KEYSYM_slash: keyName = "/"; break;
        case XCB_KEYSYM_backslash: keyName = "\\"; break;
        case XCB_KEYSYM_semicolon: keyName = ";"; break;
        case XCB_KEYSYM_quoteright: keyName = "'"; break;
        case XCB_KEYSYM_grave: keyName = "`"; break;
        case XCB_KEYSYM_parenleft: keyName = "("; break;
        case XCB_KEYSYM_parenright: keyName = ")"; break;
        case XCB_KEYSYM_bracketleft: keyName = "["; break;
        case XCB_KEYSYM_bracketright: keyName = "]"; break;
        default: break;
        }
    }
    return keyName;
}

static QString buildKeyNameLinux(xcb_keysyms_t *syms, xcb_keycode_t keycode, uint16_t state)
{
    QStringList parts;

    if (state & XCB_MOD_MASK_SHIFT) parts << "Shift";
    if (state & XCB_MOD_MASK_CONTROL) parts << "Ctrl";
    if (state & XCB_MOD_MASK_1) parts << "Alt";
    if (state & XCB_MOD_MASK_4) parts << "Win";

    QString keyName = keyTextFromXcbKeycode(syms, keycode);
    if (!keyName.isEmpty())
        parts << keyName;

    return parts.join("+");
}

static QString buildMouseButtonNameLinux(int button, uint16_t state)
{
    QStringList parts;

    if (state & XCB_MOD_MASK_SHIFT) parts << "Shift";
    if (state & XCB_MOD_MASK_CONTROL) parts << "Ctrl";
    if (state & XCB_MOD_MASK_1) parts << "Alt";
    if (state & XCB_MOD_MASK_4) parts << "Win";

    QString name = buttonNameLinux(button);
    if (!name.isEmpty())
        parts << name;

    return parts.join("+");
}

static void xiEventCallback()
{
    if (!s_xiContext.valid) return;

    xcb_generic_event_t *event;
    while ((event = xcb_poll_for_event(s_xiContext.conn))) {
        if (event->response_type == s_xiContext.event_base + XCB_INPUT_RAW_KEY_PRESS) {
            xcb_input_raw_key_press_event_t *kp =
                reinterpret_cast<xcb_input_raw_key_press_event_t *>(event);
            xcb_keysyms_t *syms = xcb_keysyms_initialize(s_xiContext.conn);
            for (auto *inst : s_activeInstances) {
                if (!inst->hasPressedKey(kp->detail)) {
                    QString displayName = buildKeyNameLinux(syms, kp->detail, kp->state);
                    inst->setPressedKey(kp->detail, displayName);
                    if (!displayName.isEmpty())
                        emit inst->keyPressed(displayName);
                }
            }
            xcb_keysyms_free(syms);
        } else if (event->response_type == s_xiContext.event_base + XCB_INPUT_RAW_KEY_RELEASE) {
            xcb_input_raw_key_release_event_t *kr =
                reinterpret_cast<xcb_input_raw_key_release_event_t *>(event);
            for (auto *inst : s_activeInstances) {
                if (inst->hasPressedKey(kr->detail)) {
                    QString displayName = inst->pressedKeyName(kr->detail);
                    inst->removePressedKey(kr->detail);
                    if (!displayName.isEmpty())
                        emit inst->keyReleased(displayName);
                }
            }
        } else if (event->response_type == s_xiContext.event_base + XCB_INPUT_RAW_BUTTON_PRESS) {
            xcb_input_raw_button_press_event_t *bp =
                reinterpret_cast<xcb_input_raw_button_press_event_t *>(event);
            int button = bp->detail;
            if (button >= 1 && button <= 5) {
                for (auto *inst : s_activeInstances) {
                    if (!inst->listenMouse()) continue;
                    if (!inst->hasPressedButton(button)) {
                        QString displayName = buildMouseButtonNameLinux(button, bp->state);
                        inst->setPressedButton(button, displayName);
                        if (!displayName.isEmpty())
                            emit inst->mousePressed(displayName);
                    }
                }
            }
        } else if (event->response_type == s_xiContext.event_base + XCB_INPUT_RAW_BUTTON_RELEASE) {
            xcb_input_raw_button_release_event_t *br =
                reinterpret_cast<xcb_input_raw_button_release_event_t *>(event);
            int button = br->detail;
            if (button >= 1 && button <= 5) {
                for (auto *inst : s_activeInstances) {
                    if (!inst->listenMouse()) continue;
                    if (inst->hasPressedButton(button)) {
                        QString displayName = inst->pressedButtonName(button);
                        inst->removePressedButton(button);
                        if (!displayName.isEmpty())
                            emit inst->mouseReleased(displayName);
                    }
                }
            }
        }
        free(event);
    }
}
#endif

TypingFollowerBackend::TypingFollowerBackend(QObject *parent)
    : QObject(parent)
{
}

TypingFollowerBackend::~TypingFollowerBackend()
{
    _listening = false;
    stopHook();
}

bool TypingFollowerBackend::listening() const
{
    return _listening;
}

void TypingFollowerBackend::listening(bool v)
{
    if (_listening == v) return;
    _listening = v;
    if (v) {
        startHook();
    } else {
        stopHook();
    }
    Q_EMIT listeningChanged();
}

bool TypingFollowerBackend::listenMouse() const
{
    return _listenMouse;
}

void TypingFollowerBackend::listenMouse(bool v)
{
    if (_listenMouse == v) return;
    _listenMouse = v;
    if (!v)
        m_pressedMouseButtons.clear();
    Q_EMIT listenMouseChanged();
}

void TypingFollowerBackend::restartHook()
{
    stopHook();
    startHook();
}

void TypingFollowerBackend::clearKeys()
{
    m_pressedKeys.clear();
    m_pressedMouseButtons.clear();
}

QString TypingFollowerBackend::keyTextFromVKey(quint32 vkey) const
{
    QString keyName;

#ifdef Q_OS_WIN
    if (vkey >= 'A' && vkey <= 'Z') {
        keyName = QChar('A' + (vkey - 'A'));
    } else if (vkey >= '0' && vkey <= '9') {
        keyName = QChar('0' + (vkey - '0'));
    } else if (vkey >= VK_F1 && vkey <= VK_F24) {
        keyName = "F" + QString::number(vkey - VK_F1 + 1);
    } else {
        switch (vkey) {
        case VK_SPACE: keyName = "Space"; break;
        case VK_RETURN: keyName = "Enter"; break;
        case VK_ESCAPE: keyName = "Escape"; break;
        case VK_TAB: keyName = "Tab"; break;
        case VK_BACK: keyName = "Backspace"; break;
        case VK_LEFT: keyName = "Left"; break;
        case VK_RIGHT: keyName = "Right"; break;
        case VK_UP: keyName = "Up"; break;
        case VK_DOWN: keyName = "Down"; break;
        case VK_SHIFT: keyName = "Shift"; break;
        case VK_CONTROL: keyName = "Ctrl"; break;
        case VK_MENU: keyName = "Alt"; break;
        case VK_CAPITAL: keyName = "CapsLock"; break;
        case VK_DELETE: keyName = "Delete"; break;
        case VK_INSERT: keyName = "Insert"; break;
        case VK_HOME: keyName = "Home"; break;
        case VK_END: keyName = "End"; break;
        case VK_PRIOR: keyName = "PageUp"; break;
        case VK_NEXT: keyName = "PageDown"; break;
        case VK_OEM_PLUS: keyName = "+"; break;
        case VK_OEM_MINUS: keyName = "-"; break;
        case VK_OEM_4: keyName = "["; break;
        case VK_OEM_6: keyName = "]"; break;
        case VK_OEM_5: keyName = "\\"; break;
        case VK_OEM_1: keyName = ";"; break;
        case VK_OEM_7: keyName = "'"; break;
        case VK_OEM_COMMA: keyName = ","; break;
        case VK_OEM_PERIOD: keyName = "."; break;
        case VK_OEM_2: keyName = "/"; break;
        case VK_OEM_3: keyName = "`"; break;
        default: break;
        }
    }
#else
    Q_UNUSED(vkey);
#endif

    return keyName;
}

void TypingFollowerBackend::startHook()
{
#ifdef Q_OS_WIN
    if (!s_activeInstances.contains(this))
        s_activeInstances.append(this);

    if (s_hookRefCount == 0) {
        s_keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, keyboardProc, NULL, 0);
        if (!s_keyboardHook)
            qWarning() << "TypingFollower: SetWindowsHookEx(KEYBOARD) failed:" << GetLastError();
        s_mouseHook = SetWindowsHookEx(WH_MOUSE_LL, mouseProc, NULL, 0);
        if (!s_mouseHook)
            qWarning() << "TypingFollower: SetWindowsHookEx(MOUSE) failed:" << GetLastError();
    }
    s_hookRefCount++;
#elif defined(Q_OS_LINUX)
    if (!s_activeInstances.contains(this))
        s_activeInstances.append(this);

    if (s_hookRefCount == 0) {
        s_xiContext.conn = xcb_connect(nullptr, nullptr);
        if (!s_xiContext.conn) {
            qWarning() << "TypingFollower: xcb_connect failed";
            s_activeInstances.removeOne(this);
            return;
        }

        xcb_setup_t *setup = xcb_get_setup(s_xiContext.conn);
        xcb_screen_t *screen = xcb_setup_roots_iterator(setup).data;
        s_xiContext.root = screen->root;

        xcb_input_query_extension_cookie_t extCookie =
            xcb_input_query_extension(s_xiContext.conn);
        xcb_input_query_extension_reply_t *extReply =
            xcb_input_query_extension_reply(s_xiContext.conn, extCookie, nullptr);
        if (!extReply) {
            qWarning() << "TypingFollower: XInput extension not available";
            free(extReply);
            xcb_disconnect(s_xiContext.conn);
            s_xiContext.conn = nullptr;
            s_activeInstances.removeOne(this);
            return;
        }

        s_xiContext.opcode = extReply->major_opcode;
        s_xiContext.event_base = extReply->first_event;
        free(extReply);

        xcb_input_select_extension_event(s_xiContext.conn, s_xiContext.root,
            XCB_INPUT_RAW_KEY_PRESS_MASK | XCB_INPUT_RAW_KEY_RELEASE_MASK |
            XCB_INPUT_RAW_BUTTON_PRESS_MASK | XCB_INPUT_RAW_BUTTON_RELEASE_MASK);
        xcb_flush(s_xiContext.conn);

        int fd = xcb_get_file_descriptor(s_xiContext.conn);
        s_notifier = new QSocketNotifier(fd, QSocketNotifier::Read, QCoreApplication::instance());
        QObject::connect(s_notifier, &QSocketNotifier::activated,
                         &xiEventCallback);
        s_notifier->setEnabled(true);
        s_xiContext.valid = true;
    }
    s_hookRefCount++;
#endif
}

void TypingFollowerBackend::stopHook()
{
#ifdef Q_OS_WIN
    s_activeInstances.removeOne(this);
    m_pressedKeys.clear();
    m_pressedMouseButtons.clear();

    s_hookRefCount--;
    if (s_hookRefCount <= 0) {
        s_hookRefCount = 0;
        if (s_keyboardHook) {
            UnhookWindowsHookEx(s_keyboardHook);
            s_keyboardHook = nullptr;
        }
        if (s_mouseHook) {
            UnhookWindowsHookEx(s_mouseHook);
            s_mouseHook = nullptr;
        }
        s_activeInstances.clear();
    }
#elif defined(Q_OS_LINUX)
    s_activeInstances.removeOne(this);
    m_pressedKeys.clear();
    m_pressedMouseButtons.clear();

    s_hookRefCount--;
    if (s_hookRefCount <= 0) {
        s_hookRefCount = 0;
        s_xiContext.valid = false;
        if (s_notifier) {
            s_notifier->setEnabled(false);
            delete s_notifier;
            s_notifier = nullptr;
        }
        if (s_xiContext.conn) {
            xcb_input_select_extension_event(s_xiContext.conn, s_xiContext.root, 0);
            xcb_flush(s_xiContext.conn);
            xcb_disconnect(s_xiContext.conn);
            s_xiContext.conn = nullptr;
        }
        s_activeInstances.clear();
    }
#endif
}