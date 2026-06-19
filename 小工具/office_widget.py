#!/usr/bin/env python3
"""
遊戲工作室 404 — 辦公室 Agent 小工具（人物版）
Mini 人偶站在等距桌子旁，上班坐著打電腦，摸魚跑去玩耍
"""

import tkinter as tk
import json
import ctypes
from pathlib import Path

SAVE_FILE = Path.home() / '.claude' / 'office_status.json'

# ── Roster ─────────────────────────────────────────────────────────────────────
AGENTS = [
    # (id, 名字, dept, idle_zone, activity)
    ('producer',         '製作人',   'mgmt',    'tea',  '喝珍奶'),
    ('monitor',          '監控師',   'mgmt',    'tea',  '盯螢幕'),
    ('gamedesigner',     '遊戲設計', 'design',  'game', '打電動'),
    ('numerics',         '數值企劃', 'design',  'tea',  '算數字'),
    ('scenedesigner',    '場景設計', 'design',  'game', '打乒乓'),
    ('tutorialdesigner', '教學設計', 'design',  'tea',  '看書'),
    ('leveldesigner',    '關卡設計', 'design',  'game', '打電動'),
    ('artdirector',      '美術規格', 'art',     'tea',  '塗鴉'),
    ('animator',         '動畫規劃', 'art',     'game', '看動畫'),
    ('effects',          '特效規格', 'art',     'game', '玩手機'),
    ('uiux',             'UI/UX',    'art',     'tea',  '滑 IG'),
    ('assets',           '素材蒐集', 'art',     'tea',  '逛網路'),
    ('content',          '內容企劃', 'content', 'tea',  '聊八卦'),
    ('writer',           '事件編劇', 'content', 'tea',  '寫小說'),
    ('sound',            '音效規劃', 'content', 'tea',  '聽音樂'),
    ('localization',     '在地化',   'content', 'tea',  '看韓劇'),
    ('programmer',       '程式設計', 'tech',    'game', '打 CS2'),
    ('sysprogrammer',    '系統程式', 'tech',    'game', '修電腦'),
    ('dataarchitect',    '資料架構', 'tech',    'tea',  '看XKCD'),
    ('datamanager',      '資料管理', 'tech',    'tea',  '整理桌'),
    ('toolsdev',         '工具開發', 'tech',    'game', '改鍵盤'),
    ('performance',      '效能優化', 'tech',    'game', '跑來跑'),
    ('tester',           '測試員',   'qa',      'game', '找 bug'),
    ('validator',        '數值驗證', 'qa',      'game', '玩手遊'),
    ('release',          '發布規劃', 'qa',      'tea',  '規劃旅行'),
]

# (shirt_color, skin_highlight)
DEPT_SHIRT = {
    'mgmt':    '#7C3AED',
    'design':  '#2563EB',
    'art':     '#DB2777',
    'content': '#D97706',
    'tech':    '#059669',
    'qa':      '#DC2626',
}

# Activity emoji shown above idle characters
IDLE_EMOJI = {
    '喝珍奶': '🧋', '盯螢幕': '📡', '打電動': '🎮', '算數字': '🔢',
    '打乒乓': '🏓', '看書': '📖', '塗鴉': '✏️', '看動畫': '🎬',
    '玩手機': '📱', '滑 IG': '📸', '逛網路': '🌐', '聊八卦': '💬',
    '寫小說': '📝', '聽音樂': '🎵', '看韓劇': '📺', '打 CS2': '🔫',
    '修電腦': '🔧', '看XKCD': '😂', '整理桌': '📁', '改鍵盤': '⌨️',
    '跑來跑': '🏃', '找 bug': '🐛', '玩手遊': '📱', '規劃旅行': '✈️',
}

# ── Layout ─────────────────────────────────────────────────────────────────────
CW, CH = 640, 490
HDR    = 48
WORK_W = 405
SIDE_W = CW - WORK_W          # 235
GAME_H = (CH - HDR) // 2      # 221
TEA_H  = CH - HDR - GAME_H    # 221

DCOLS, DROWS = 5, 4
CELL_W = WORK_W // DCOLS      # 81
CELL_H = (CH - HDR) // DROWS  # 110


# ── Widget ─────────────────────────────────────────────────────────────────────
class OfficeWidget(tk.Tk):

    BG   = '#111111'
    SKIN = '#FBBF24'   # character face
    HAIR = '#78350F'   # hair
    PANTS= '#374151'   # pants/legs

    def __init__(self):
        super().__init__()
        self.overrideredirect(True)
        self.attributes('-topmost', True)
        self.configure(bg=self.BG)

        self._pinned   = True
        self._blink    = True
        self._state    = {}
        self._px = self._py = 0
        self._from_hdr = False
        self._dragging = False

        self._load()

        wrap = tk.Frame(self, bg=self.BG, padx=2, pady=2)
        wrap.pack()

        self._cv = tk.Canvas(wrap, width=CW, height=CH,
                             highlightthickness=0, bg='#EDE7DC')
        self._cv.pack()

        self._cv.bind('<ButtonPress-1>',   self._on_press)
        self._cv.bind('<B1-Motion>',       self._on_drag)
        self._cv.bind('<ButtonRelease-1>', self._on_release)

        self._draw()

        self.update_idletasks()
        sw, sh = self.winfo_screenwidth(), self.winfo_screenheight()
        self.geometry(f'+{(sw - CW) // 2}+{(sh - CH) // 2}')
        self.bind('<Map>', lambda _: self.after(200, self._taskbar))
        self._tick()

    # ── Draw ───────────────────────────────────────────────────────────────────

    def _draw(self):
        cv = self._cv
        cv.delete('all')
        self._draw_floor()
        self._draw_side_rooms()
        self._draw_partition()
        self._draw_work_area()
        self._draw_idle_area()
        self._draw_header()   # drawn last so it's on top

    # ── Floor tiles ────────────────────────────────────────────────────────────

    def _draw_floor(self):
        t = 36
        a, b = '#EDE7DC', '#E2D9CC'
        for r in range((CH - HDR) // t + 2):
            for c in range(WORK_W // t + 2):
                x0, y0 = c * t, HDR + r * t
                self._cv.create_rectangle(x0, y0, x0 + t, y0 + t,
                                          fill=a if (r+c)%2==0 else b,
                                          outline='')

    # ── Side rooms ─────────────────────────────────────────────────────────────

    def _draw_side_rooms(self):
        cv = self._cv
        # game room
        cv.create_rectangle(WORK_W, HDR, CW, HDR + GAME_H,
                            fill='#E3F2E8', outline='')
        cv.create_rectangle(WORK_W, HDR, CW, HDR + GAME_H,
                            fill='', outline='#86EFAC', width=2)
        cv.create_text(WORK_W + 10, HDR + 14, anchor='w',
                       text='🎮  遊戲間',
                       font=('Segoe UI Emoji', 11, 'bold'),
                       fill='#166534')
        cv.create_text(WORK_W + SIDE_W // 2, HDR + 35,
                       text='🕹   🏓   📺',
                       font=('Segoe UI Emoji', 14), fill='#4ADE80')

        # tea room
        ty = HDR + GAME_H
        cv.create_rectangle(WORK_W, ty, CW, CH,
                            fill='#FFF8E0', outline='')
        cv.create_rectangle(WORK_W, ty, CW, CH,
                            fill='', outline='#FCD34D', width=2)
        cv.create_text(WORK_W + 10, ty + 14, anchor='w',
                       text='☕  茶水間',
                       font=('Segoe UI Emoji', 11, 'bold'),
                       fill='#92400E')
        cv.create_text(WORK_W + SIDE_W // 2, ty + 35,
                       text='🧋   ☕   🌿',
                       font=('Segoe UI Emoji', 14), fill='#D97706')

    def _draw_partition(self):
        self._cv.create_line(WORK_W, HDR, WORK_W, CH,
                             fill='#B8A88A', width=3)

    # ── Work area (desks + characters) ─────────────────────────────────────────

    def _draw_work_area(self):
        working = [a for a in AGENTS if self._state.get(a[0]) == 'working']

        for slot in range(DCOLS * DROWS):
            col, row = slot % DCOLS, slot // DCOLS
            # cell center
            cx = col * CELL_W + CELL_W // 2
            cy = HDR + row * CELL_H + CELL_H // 2

            # desk sits in lower half of cell
            desk_cx = cx
            desk_cy = cy + 22   # push desk down within cell

            occupied = slot < len(working)
            self._draw_iso_desk(desk_cx, desk_cy, occupied)

            if occupied:
                agent = working[slot]
                char_cx = desk_cx
                char_cy = desk_cy - 28   # character appears BEHIND desk
                self._draw_person(char_cx, char_cy, agent[2], working=True, tag=f'ag_{agent[0]}')
                # name under desk
                cv = self._cv
                cv.create_text(desk_cx, desk_cy + 22, anchor='center',
                               text=agent[1],
                               font=('Microsoft JhengHei UI', 7, 'bold'),
                               fill='#4B3621', tags=f'lbl_{agent[0]}')
            else:
                # empty label
                self._cv.create_text(desk_cx, desk_cy + 22, anchor='center',
                                     text='空位',
                                     font=('Segoe UI', 7),
                                     fill='#C4A882')

    # ── Isometric desk ─────────────────────────────────────────────────────────

    def _draw_iso_desk(self, cx, cy, occupied):
        cv  = self._cv
        dw  = 58   # iso width
        th  = 11   # top face height (iso perspective)
        fh  = 13   # front face height

        top_col   = '#A07850' if occupied else '#9A7B5A'
        left_col  = '#6B4F30' if occupied else '#7C6245'
        right_col = '#7D5C38' if occupied else '#8B6B47'

        # top surface (diamond)
        top = [cx, cy - th,
               cx + dw//2, cy - th//2,
               cx, cy,
               cx - dw//2, cy - th//2]
        cv.create_polygon(top, fill=top_col, outline='#4A2E10', width=1)

        # left face
        lft = [cx - dw//2, cy - th//2,
               cx, cy,
               cx, cy + fh,
               cx - dw//2, cy - th//2 + fh]
        cv.create_polygon(lft, fill=left_col, outline='#4A2E10', width=1)

        # right face
        rgt = [cx + dw//2, cy - th//2,
               cx, cy,
               cx, cy + fh,
               cx + dw//2, cy - th//2 + fh]
        cv.create_polygon(rgt, fill=right_col, outline='#4A2E10', width=1)

        # monitor on top surface
        mx, my = cx + 8, cy - th - 2
        # monitor screen
        cv.create_rectangle(mx - 9, my - 12, mx + 9, my,
                            fill='#1F2937', outline='#111')
        glow = '#3B82F6' if occupied else '#374151'
        cv.create_rectangle(mx - 8, my - 11, mx + 8, my - 1, fill=glow)
        if occupied and self._blink:
            # blinking cursor on screen
            cv.create_rectangle(mx + 2, my - 4, mx + 4, my - 2, fill='#93C5FD')
        # monitor stand
        cv.create_line(mx, my, mx - 2, my + 4, fill='#374151', width=2)
        # keyboard
        cv.create_rectangle(cx - 16, cy - th//2 + 2, cx + 2, cy - th//2 + 6,
                            fill='#D1D5DB', outline='#9CA3AF', width=1)

    # ── Mini person ────────────────────────────────────────────────────────────

    def _draw_person(self, cx, cy, dept, working, tag='', activity=''):
        cv    = self._cv
        shirt = DEPT_SHIRT.get(dept, '#6B7280')

        # ── head ──
        hr = 9
        hx, hy = cx, cy - 14
        cv.create_oval(hx - hr, hy - hr, hx + hr, hy + hr,
                       fill=self.SKIN, outline='#D97706', width=1, tags=tag)
        # hair
        cv.create_arc(hx - hr, hy - hr, hx + hr, hy - 2,
                      start=0, extent=180, fill=self.HAIR,
                      outline='', style='chord', tags=tag)
        # eyes
        ey = hy - 1
        cv.create_oval(hx-4, ey-2, hx-2, ey, fill='#1F2937', tags=tag)
        cv.create_oval(hx+2, ey-2, hx+4, ey, fill='#1F2937', tags=tag)
        # mouth
        if working:
            # focused straight line
            cv.create_line(hx-3, hy+4, hx+3, hy+4, fill='#92400E', width=1, tags=tag)
        else:
            # happy curve
            cv.create_arc(hx-4, hy+1, hx+4, hy+7,
                          start=200, extent=140, style='arc',
                          outline='#92400E', width=1, tags=tag)

        # ── body / torso ──
        # shirt (visible above desk when at desk, full when idle)
        bx0, by0, bx1, by1 = cx-7, cy-4, cx+7, cy+8
        cv.create_rectangle(bx0, by0, bx1, by1,
                            fill=shirt, outline='', tags=tag)
        # collar line
        cv.create_line(cx-2, by0, cx, by0+3, cx+2, by0,
                       fill='white', width=1, tags=tag)

        if working:
            # arms reach toward keyboard (angled down-forward)
            cv.create_line(cx-7, cy, cx-14, cy+8, fill=self.SKIN, width=3, tags=tag)
            cv.create_line(cx+7, cy, cx+14, cy+8, fill=self.SKIN, width=3, tags=tag)
            # hands
            cv.create_oval(cx-17, cy+6, cx-11, cy+12, fill=self.SKIN, outline='', tags=tag)
            cv.create_oval(cx+11, cy+6, cx+17, cy+12, fill=self.SKIN, outline='', tags=tag)
        else:
            # arms relaxed at sides
            cv.create_line(cx-7, cy, cx-11, cy+6, fill=self.SKIN, width=3, tags=tag)
            cv.create_line(cx+7, cy, cx+11, cy+6, fill=self.SKIN, width=3, tags=tag)
            # legs
            cv.create_line(cx-3, by1, cx-4, by1+10, fill=self.PANTS, width=3, tags=tag)
            cv.create_line(cx+3, by1, cx+4, by1+10, fill=self.PANTS, width=3, tags=tag)
            # shoes
            cv.create_oval(cx-7, by1+8, cx-1, by1+13, fill='#1F2937', tags=tag)
            cv.create_oval(cx+1, by1+8, cx+7, by1+13, fill='#1F2937', tags=tag)

        # ── status dot (top-right of head) ──
        dot = '#22C55E' if working else '#9CA3AF'
        if working and not self._blink:
            dot = '#86EFAC'
        cv.create_oval(hx+hr-3, hy-hr-1, hx+hr+5, hy-hr+7,
                       fill=dot, outline='white', width=1, tags=tag)

        # ── activity emoji above head (idle only) ──
        if not working and activity:
            emo = IDLE_EMOJI.get(activity, '😴')
            cv.create_text(hx, hy - hr - 10, anchor='s',
                           text=emo,
                           font=('Segoe UI Emoji', 12),
                           tags=tag)

    # ── Idle area placement ────────────────────────────────────────────────────

    def _draw_idle_area(self):
        game = [a for a in AGENTS if self._state.get(a[0]) != 'working' and a[3] == 'game']
        tea  = [a for a in AGENTS if self._state.get(a[0]) != 'working' and a[3] == 'tea']
        self._place_idle(game, WORK_W, HDR + 58,          SIDE_W, GAME_H - 60)
        self._place_idle(tea,  WORK_W, HDR + GAME_H + 58, SIDE_W, TEA_H  - 60)

    def _place_idle(self, agents, zx, zy, zw, zh):
        if not agents:
            return
        n = len(agents)
        # character total height ~40px, width ~40px → cell
        cw = 48 if n <= 8 else 42 if n <= 15 else 36
        ch = 52 if n <= 8 else 46 if n <= 15 else 40
        cols = max(1, zw // cw)
        for i, agent in enumerate(agents):
            c, row = i % cols, i // cols
            cx = zx + c * cw + cw // 2
            # character body bottom anchored to cy; head above
            cy = zy + row * ch + ch // 2 - 4
            if cy + 25 <= zy + zh:
                tag = f'ag_{agent[0]}'
                self._draw_person(cx, cy, agent[2], working=False,
                                  tag=tag, activity=agent[4])
                self._cv.create_text(cx, cy + 22, anchor='center',
                                     text=agent[1],
                                     font=('Microsoft JhengHei UI', 6),
                                     fill='#374151', tags=f'lbl_{agent[0]}')

    # ── Header ─────────────────────────────────────────────────────────────────

    def _draw_header(self):
        cv = self._cv
        cv.create_rectangle(0, 0, CW, HDR, fill='#0F2550', outline='')
        # halftone
        for x in range(0, CW, 9):
            for y in range(0, HDR, 9):
                cv.create_oval(x, y, x+3, y+3, fill='#0A1A3C', outline='')

        cv.create_text(14, HDR//2, anchor='w',
                       text='🏢 遊戲工作室 404',
                       font=('Segoe UI Emoji', 12, 'bold'),
                       fill='white')

        w = sum(1 for v in self._state.values() if v == 'working')
        cv.create_text(CW//2, HDR//2, anchor='center',
                       text=f'在工作 {w}  ·  摸魚 {len(AGENTS)-w}  ·  共 {len(AGENTS)}',
                       font=('Segoe UI', 9),
                       fill='#93C5FD')

        pin = '#16A34A' if self._pinned else '#4B5563'
        self._hdr_btn(CW-55, '📌', pin, 'btn_pin')
        self._hdr_btn(CW-25, '×', '#B91C1C', 'btn_close')

    def _hdr_btn(self, cx, txt, fill, tag):
        cv = self._cv
        cv.create_rectangle(cx-14, 8, cx+14, HDR-8, fill=fill, outline='', tags=tag)
        cv.create_text(cx, HDR//2, text=txt,
                       font=('Segoe UI Emoji', 9, 'bold'),
                       fill='white', tags=tag)

    # ── Interaction ────────────────────────────────────────────────────────────

    def _on_press(self, e):
        self._px, self._py = e.x, e.y
        self._from_hdr = e.y < HDR
        self._dragging = False

    def _on_drag(self, e):
        if self._from_hdr:
            self._dragging = True
            x = self.winfo_x() + e.x - self._px
            y = self.winfo_y() + e.y - self._py
            self.geometry(f'+{x}+{y}')

    def _on_release(self, e):
        if self._dragging:
            return
        if self._from_hdr:
            if abs(e.x - (CW-25)) <= 14 and 8 <= e.y <= HDR-8:
                self.destroy(); return
            if abs(e.x - (CW-55)) <= 14 and 8 <= e.y <= HDR-8:
                self._pinned = not self._pinned
                self.attributes('-topmost', self._pinned)
                self._draw(); return
            return
        # click on agent
        for item in self._cv.find_closest(e.x, e.y, halo=14):
            for tag in self._cv.gettags(item):
                if tag.startswith('ag_'):
                    self._toggle(tag[3:]); return

    # ── State ──────────────────────────────────────────────────────────────────

    def _load(self):
        try:
            if SAVE_FILE.exists():
                self._state = json.loads(SAVE_FILE.read_text(encoding='utf-8'))
        except Exception:
            self._state = {}
        for a in AGENTS:
            if a[0] not in self._state:
                self._state[a[0]] = 'idle'

    def _save(self):
        try:
            SAVE_FILE.parent.mkdir(parents=True, exist_ok=True)
            SAVE_FILE.write_text(json.dumps(self._state, ensure_ascii=False),
                                 encoding='utf-8')
        except Exception:
            pass

    def _toggle(self, aid):
        self._state[aid] = ('idle' if self._state.get(aid) == 'working' else 'working')
        self._save()
        self._draw()

    # ── Animation & system ─────────────────────────────────────────────────────

    def _tick(self):
        self._blink = not self._blink
        self._draw()
        self.after(900, self._tick)

    def _taskbar(self):
        try:
            hwnd = self.winfo_id()
            EX, APP, TOOL = -20, 0x00040000, 0x00000080
            style = ctypes.windll.user32.GetWindowLongW(hwnd, EX)
            ctypes.windll.user32.SetWindowLongW(hwnd, EX, (style & ~TOOL) | APP)
            ctypes.windll.user32.SetWindowPos(hwnd, 0, 0, 0, 0, 0, 0x27)
        except Exception:
            pass


if __name__ == '__main__':
    OfficeWidget().mainloop()
