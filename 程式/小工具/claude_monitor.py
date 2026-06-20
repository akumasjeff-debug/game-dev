#!/usr/bin/env python3
"""
Claude Code Desktop Monitor Widget
Comic Style  🐷 & 🦄
"""

import tkinter as tk
import tkinter.ttk as ttk
import json
import threading
import time
import ctypes
from pathlib import Path

TOKEN_FILE  = Path.home() / '.claude' / 'token_monitor.json'
REMOTE_FILE = Path.home() / '.claude' / 'remote_status.json'
APP_TITLE   = 'Claude Monitor 🐷🦄'


def _force_taskbar(hwnd: int) -> None:
    try:
        GWL_EXSTYLE      = -20
        WS_EX_APPWINDOW  = 0x00040000
        WS_EX_TOOLWINDOW = 0x00000080
        style = ctypes.windll.user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
        style = (style & ~WS_EX_TOOLWINDOW) | WS_EX_APPWINDOW
        ctypes.windll.user32.SetWindowLongW(hwnd, GWL_EXSTYLE, style)
        ctypes.windll.user32.SetWindowPos(hwnd, 0, 0, 0, 0, 0, 0x27)
    except Exception:
        pass


def _fmt(n: int) -> str:
    return f'{n:,}'


class ClaudeMonitor(tk.Tk):

    C = {
        'bg':      '#FFFDE7',
        'border':  '#1A1A1A',
        'header':  '#FF6F00',
        'hdr_dot': '#CC5500',
        'panel_y': '#FFF9C4',
        'panel_b': '#DBEAFE',
        'panel_g': '#DCFCE7',
        'row_alt': '#F0F9FF',
        'text':    '#111827',
        'blue':    '#1D4ED8',
        'green':   '#15803D',
        'red':     '#DC2626',
        'orange':  '#EA580C',
        'white':   '#FFFFFF',
        'gray':    '#9CA3AF',
        'amber':   '#D97706',
    }

    def __init__(self):
        super().__init__()
        self.title(APP_TITLE)
        self.overrideredirect(True)
        self.attributes('-topmost', True)
        self._pinned = True
        self._dx = self._dy = 0

        self.configure(bg=self.C['border'])
        self._setup_styles()
        self._build_ui()
        self._place_window()
        self.bind('<Map>', lambda _: self.after(200, self._show_in_taskbar))
        threading.Thread(target=self._monitor_loop, daemon=True).start()

    # ── ttk styling ───────────────────────────────────────────────────────────

    def _setup_styles(self):
        s = ttk.Style(self)
        s.theme_use('clam')

        s.configure('Token.Treeview',
                    background=self.C['bg'],
                    fieldbackground=self.C['bg'],
                    foreground=self.C['text'],
                    rowheight=22,
                    font=('Arial', 8),
                    borderwidth=0,
                    relief='flat')
        s.configure('Token.Treeview.Heading',
                    background=self.C['panel_b'],
                    foreground=self.C['blue'],
                    font=('Arial', 8, 'bold'),
                    relief='flat')
        s.map('Token.Treeview',
              background=[('selected', '#BFDBFE')],
              foreground=[('selected', self.C['text'])])

        s.configure('Token.Vertical.TScrollbar',
                    background=self.C['panel_y'],
                    troughcolor=self.C['bg'],
                    arrowcolor=self.C['border'],
                    borderwidth=1,
                    relief='flat')

    # ── UI ────────────────────────────────────────────────────────────────────

    def _build_ui(self):
        wrap = tk.Frame(self, bg=self.C['bg'])
        wrap.pack(padx=2, pady=2)
        self._build_header(wrap)
        self._build_tokens(wrap)
        self._build_remote(wrap)
        self._build_footer(wrap)

    def _sep(self, parent):
        tk.Frame(parent, height=2, bg=self.C['border']).pack(fill='x')

    # ── Header ────────────────────────────────────────────────────────────────

    def _build_header(self, p):
        self._hdr = tk.Canvas(p, height=52, highlightthickness=0,
                              bg=self.C['header'])
        self._hdr.pack(fill='x')
        for x in range(0, 300, 9):
            for y in range(0, 54, 9):
                self._hdr.create_oval(x, y, x+4, y+4,
                                      fill=self.C['hdr_dot'], outline='')

        close = tk.Label(p, text=' × ', font=('Arial', 11, 'bold'),
                         bg='#B91C1C', fg=self.C['white'], cursor='hand2')
        close.place(in_=self._hdr, relx=1, x=-2, y=2, anchor='ne')
        close.bind('<Button-1>', lambda _: self.destroy())

        self._hdr.after(50, self._draw_title)
        self._hdr.bind('<Button-1>',  self._drag_start)
        self._hdr.bind('<B1-Motion>', self._drag_move)

    def _draw_title(self):
        c  = self._hdr
        cw = c.winfo_width() or 280
        for dx, dy in ((-1,-1),(1,-1),(-1,1),(1,1)):
            c.create_text(cw//2+dx, 26+dy, text='🐷  CLAUDE MONITOR  🦄',
                          font=('Impact', 13), fill=self.C['border'])
        c.create_text(cw//2, 26, text='🐷  CLAUDE MONITOR  🦄',
                      font=('Impact', 13), fill=self.C['white'])

    # ── Token scrollable list ─────────────────────────────────────────────────

    def _build_tokens(self, p):
        self._sep(p)

        # Section label
        badge = tk.Frame(p, bg=self.C['panel_y'])
        badge.pack(fill='x')
        tk.Label(badge, text='⚡  每段對話的 Token 用量（最新在上）  ⚡',
                 font=('Arial', 8, 'bold'),
                 bg=self.C['panel_y'], fg=self.C['blue'], pady=3).pack()

        self._sep(p)

        # Treeview + scrollbar
        tree_frame = tk.Frame(p, bg=self.C['bg'])
        tree_frame.pack(fill='x')

        cols = ('time', 'input', 'output', 'total')
        self._tree = ttk.Treeview(tree_frame, columns=cols,
                                  show='headings', height=6,
                                  style='Token.Treeview',
                                  selectmode='browse')

        self._tree.heading('time',   text='時間')
        self._tree.heading('input',  text='輸入\n（你傳的文字）')
        self._tree.heading('output', text='輸出\n（Claude 回應）')
        self._tree.heading('total',  text='合計')

        self._tree.column('time',   width=54,  anchor='center', stretch=False)
        self._tree.column('input',  width=82,  anchor='e',      stretch=True)
        self._tree.column('output', width=82,  anchor='e',      stretch=True)
        self._tree.column('total',  width=62,  anchor='e',      stretch=False)

        self._tree.tag_configure('even', background=self.C['bg'])
        self._tree.tag_configure('odd',  background=self.C['row_alt'])
        self._tree.bind('<<TreeviewSelect>>', self._on_row_select)

        sb = ttk.Scrollbar(tree_frame, orient='vertical',
                           command=self._tree.yview,
                           style='Token.Vertical.TScrollbar')
        self._tree.configure(yscrollcommand=sb.set)

        self._tree.pack(side='left', fill='both', expand=True)
        sb.pack(side='right', fill='y')

        # Message bubble — shown when a row is selected
        bubble = tk.Frame(p, bg=self.C['panel_b'])
        bubble.pack(fill='x', padx=6, pady=(0, 4))

        tk.Label(bubble, text='💬 你說了什麼：',
                 font=('Arial', 7, 'bold'),
                 bg=self.C['panel_b'], fg=self.C['blue'],
                 anchor='w').pack(fill='x', padx=6, pady=(4, 0))

        self.lbl_msg = tk.Label(bubble,
                                text='← 點選上方任一列查看',
                                font=('Arial', 8),
                                bg=self.C['panel_b'], fg=self.C['gray'],
                                wraplength=270, justify='left', anchor='w',
                                pady=3, padx=6)
        self.lbl_msg.pack(fill='x')

        self._entry_messages: dict[str, str] = {}

        self._sep(p)

    # ── Remote section ────────────────────────────────────────────────────────

    def _build_remote(self, p):
        sec = tk.Frame(p, bg=self.C['bg'])
        sec.pack(fill='x', padx=8, pady=8)

        row = tk.Frame(sec, bg=self.C['bg'])
        row.pack(fill='x')
        tk.Label(row, text='📱 手機遠端：',
                 font=('Arial', 9, 'bold'),
                 bg=self.C['bg'], fg=self.C['text']).pack(side='left')

        # Light is clickable — acts as manual toggle
        self._light_cv = tk.Canvas(row, width=26, height=26,
                                   bg=self.C['bg'], highlightthickness=0,
                                   cursor='hand2')
        self._light_cv.pack(side='left', padx=5)
        self._light_cv.bind('<Button-1>', lambda _: self._toggle_remote())

        self.lbl_remote = tk.Label(row, text='未連線',
                                   font=('Arial', 11, 'bold'),
                                   bg=self.C['bg'], fg=self.C['red'],
                                   cursor='hand2')
        self.lbl_remote.pack(side='left')
        self.lbl_remote.bind('<Button-1>', lambda _: self._toggle_remote())

        hint = tk.Label(row, text='← 點燈切換',
                        font=('Arial', 7), bg=self.C['bg'], fg=self.C['gray'])
        hint.pack(side='left', padx=(4, 0))

        self._draw_light(False)

        self.btn_copy = tk.Button(
            sec,
            text='📋  複製 /remote-control 指令',
            font=('Arial', 9, 'bold'),
            bg=self.C['amber'], fg=self.C['white'],
            relief='flat', pady=7, cursor='hand2',
            bd=0, highlightthickness=2,
            highlightbackground=self.C['border'],
            activebackground='#B45309', activeforeground=self.C['white'],
            command=self._copy_remote)
        self.btn_copy.pack(fill='x', pady=(6, 0))

        self.lbl_flash = tk.Label(sec, text='', font=('Arial', 8),
                                  bg=self.C['bg'], fg=self.C['green'])
        self.lbl_flash.pack()

        self._sep(p)

    # ── Footer ────────────────────────────────────────────────────────────────

    def _build_footer(self, p):
        f = tk.Frame(p, bg=self.C['bg'])
        f.pack(fill='x', padx=6, pady=6)

        self.btn_pin = tk.Button(
            f, text='📌 置頂：開',
            font=('Arial', 8, 'bold'),
            bg='#16A34A', fg=self.C['white'],
            relief='flat', padx=6, pady=4, cursor='hand2',
            bd=0, highlightthickness=2,
            highlightbackground=self.C['border'],
            activebackground='#15803D',
            command=self._toggle_pin)
        self.btn_pin.pack(side='left')

        tk.Label(f, text='🐷✨🦄', font=('Segoe UI Emoji', 12),
                 bg=self.C['bg']).pack(side='left', expand=True)

        tk.Button(f, text='↺', font=('Arial', 12),
                  bg=self.C['panel_y'], fg=self.C['text'],
                  relief='flat', padx=4, pady=2, cursor='hand2',
                  bd=0, highlightthickness=2,
                  highlightbackground=self.C['border'],
                  command=self._refresh).pack(side='right')

    # ── Light ─────────────────────────────────────────────────────────────────

    def _draw_light(self, on: bool):
        c = self._light_cv
        c.delete('all')
        outer = '#22C55E' if on else '#EF4444'
        inner = '#86EFAC' if on else '#FCA5A5'
        c.create_oval(1, 1, 25, 25, fill=outer,
                      outline=self.C['border'], width=1.5)
        c.create_oval(6, 6, 20, 20, fill=inner, outline='')
        c.create_oval(8, 8, 12, 12, fill=self.C['white'], outline='')

    # ── Drag ──────────────────────────────────────────────────────────────────

    def _drag_start(self, e):
        self._dx, self._dy = e.x, e.y

    def _drag_move(self, e):
        x = self.winfo_x() + e.x - self._dx
        y = self.winfo_y() + e.y - self._dy
        self.geometry(f'+{x}+{y}')

    # ── Actions ───────────────────────────────────────────────────────────────

    def _toggle_pin(self):
        self._pinned = not self._pinned
        self.attributes('-topmost', self._pinned)
        self.btn_pin.configure(
            text='📌 置頂：開' if self._pinned else '📌 置頂：關',
            bg='#16A34A' if self._pinned else self.C['gray'])

    def _copy_remote(self):
        self.clipboard_clear()
        self.clipboard_append('/remote-control')
        self.update()
        self.lbl_flash.configure(text='✓ 已複製！貼上到 Claude 終端機')
        self.after(3000, lambda: self.lbl_flash.configure(text=''))

    def _refresh(self):
        threading.Thread(target=self._check_remote, daemon=True).start()
        threading.Thread(target=self._read_tokens,  daemon=True).start()

    # ── Data ──────────────────────────────────────────────────────────────────

    def _toggle_remote(self):
        """手動切換遠端狀態，並寫入狀態檔。"""
        current = False
        if REMOTE_FILE.exists():
            try:
                current = bool(json.loads(REMOTE_FILE.read_text()).get('active'))
            except Exception:
                pass
        new_state = not current
        REMOTE_FILE.parent.mkdir(parents=True, exist_ok=True)
        REMOTE_FILE.write_text(json.dumps({'active': new_state}))
        self._apply_remote(new_state)

    def _check_remote(self):
        """讀取手動設定的狀態檔。"""
        active = False
        if REMOTE_FILE.exists():
            try:
                active = bool(json.loads(REMOTE_FILE.read_text()).get('active'))
            except Exception:
                pass
        self.after(0, self._apply_remote, active)

    def _apply_remote(self, active: bool):
        self._draw_light(active)
        if active:
            self.lbl_remote.configure(text='已連線', fg=self.C['green'])
            self.btn_copy.configure(state='disabled', bg=self.C['gray'],
                                    text='✓  遠端已啟動')
        else:
            self.lbl_remote.configure(text='未連線', fg=self.C['red'])
            self.btn_copy.configure(state='normal', bg=self.C['amber'],
                                    text='📋  複製 /remote-control 指令')

    def _read_tokens(self):
        if not TOKEN_FILE.exists():
            return
        try:
            raw = json.loads(TOKEN_FILE.read_text())
            # Support both list (new) and single dict (old) formats
            entries = raw if isinstance(raw, list) else [raw]
            self.after(0, self._apply_tokens, entries)
        except Exception:
            pass

    def _on_row_select(self, _event):
        sel = self._tree.selection()
        if not sel:
            return
        msg = self._entry_messages.get(sel[0], '')
        if msg:
            preview = msg[:300] + ('…' if len(msg) > 300 else '')
            self.lbl_msg.configure(text=preview, fg=self.C['text'])
        else:
            self.lbl_msg.configure(text='（此筆無訊息記錄）', fg=self.C['gray'])

    def _apply_tokens(self, entries: list):
        # Remember selected iid to restore after rebuild
        sel_before = self._tree.selection()
        sel_values = (self._tree.item(sel_before[0], 'values')
                      if sel_before else None)

        for iid in self._tree.get_children():
            self._tree.delete(iid)
        self._entry_messages.clear()

        restore_iid = None
        for i, e in enumerate(entries):
            inp   = int(e.get('input_tokens',  0))
            out   = int(e.get('output_tokens', 0))
            total = inp + out
            tag   = 'even' if i % 2 == 0 else 'odd'
            iid   = self._tree.insert('', 'end', values=(
                e.get('timestamp', '─'),
                _fmt(inp),
                _fmt(out),
                _fmt(total),
            ), tags=(tag,))
            self._entry_messages[iid] = e.get('message', '')
            if sel_values and self._tree.item(iid, 'values') == sel_values:
                restore_iid = iid

        if restore_iid:
            self._tree.selection_set(restore_iid)

    # ── Monitor thread ────────────────────────────────────────────────────────

    def _monitor_loop(self):
        while True:
            try:
                self._check_remote()
                self._read_tokens()
            except Exception:
                pass
            time.sleep(3)

    def _show_in_taskbar(self):
        _force_taskbar(self.winfo_id())

    def _place_window(self):
        self.update_idletasks()
        w  = self.winfo_reqwidth()
        sw = self.winfo_screenwidth()
        self.geometry(f'+{sw - w - 20}+20')


if __name__ == '__main__':
    ClaudeMonitor().mainloop()
