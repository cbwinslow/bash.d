package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/textarea"
	"github.com/charmbracelet/bubbles/viewport"
	"github.com/charmbracelet/glamour"
	"github.com/charmbracelet/lipgloss"
)

const (
	width  = 100
	height = 30
)

var (
	titleStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("205"))
	tabStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("63"))
	activeTabStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("39"))
	helpStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("241"))
	boxStyle  = lipgloss.NewStyle().Padding(0,1)
)

// layout modes
const (
	LayoutSingle = iota
	LayoutVerticalSplit
	LayoutHorizontalSplit
)

// fileItem implements list.Item
type fileItem struct{
	name string
	path string
	isDir bool
}
func (f fileItem) Title() string { return f.name }
func (f fileItem) Description() string { if f.isDir { return "directory" }; return "file" }
func (f fileItem) FilterValue() string { return f.name }

// agentItem implements list.Item for agents
type agentItem struct{
	name string
	desc string
}
func (a agentItem) Title() string { return a.name }
func (a agentItem) Description() string { return a.desc }
func (a agentItem) FilterValue() string { return a.name }

// requestItem for Requests tab
type requestItem struct{
	ID string `json:"id"`
	Agent string `json:"agent"`
	User string `json:"user"`
	Time string `json:"time"`
	Notes string `json:"notes,omitempty"`
}
func (r requestItem) Title() string { return fmt.Sprintf("%s by %s", r.Agent, r.User) }
func (r requestItem) Description() string { return r.Time }
func (r requestItem) FilterValue() string { return r.Agent + " " + r.User }

type model struct{
	list list.Model
	agentsList list.Model
	requestsList list.Model
	vp viewport.Model
	ti textinput.Model
	ta textarea.Model
	cwd string
	tabs []string
	active int
	status string
	layout int
	mdTheme string // "dark" or "light"
	editorFile string // path of file currently loaded into editor
	auditPath string
	auditContent string
	requestsPath string
	pluginsList list.Model
}

func initialModel() model {
	cwd, _ := os.Getwd()
	items := listItemsFromDir(cwd)
	l := list.New(items, list.NewDefaultDelegate(), 30, height-8)
	l.Title = "Files: " + cwd
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(true)
	l.SetShowHelp(false)

	// Agents list
	agents := loadAgents()
	agList := list.New(agents, list.NewDefaultDelegate(), 40, height-8)
	agList.Title = "Agents"
	agList.SetShowHelp(false)

	// Requests list
	home, _ := os.UserHomeDir()
	requestsPath := filepath.Join(home, ".bash_functions_d", "tui", "requests.json")
	// ensure dir
	_ = os.MkdirAll(filepath.Dir(requestsPath), 0o700)
	reqs := loadRequests(requestsPath)
	reqList := list.New(reqs, list.NewDefaultDelegate(), 60, height-8)
	reqList.Title = "Requests"

	// Plugins list
	plugins := loadPlugins()
	plList := list.New(plugins, list.NewDefaultDelegate(), 40, height-8)
	plList.Title = "Plugins"

	vp := viewport.New(width-32, height-10)
	vp.SetContent("Welcome to the TUI. Select a file and press Enter to preview or press 'e' to edit. Press 'E' to open in embedded editor.\n")

	ti := textinput.New()
	ti.Placeholder = "enter shell command and press Enter"
	ti.CharLimit = 512
	ti.Width = width-34

	// embedded textarea editor
	ta := textarea.New()
	ta.Placeholder = "Write script here. Ctrl+S to save, Ctrl+Q to exit editor."
	ta.SetWidth(width-34)
	ta.SetHeight(height-12)
	ta.ShowLineNumbers = true

	tabs := []string{"Files", "Agents", "Requests", "Audit", "Plugins", "Preview", "Editor", "Shell", "Image", "YouTube"}

	home, _ = os.UserHomeDir()
	auditDir := filepath.Join(home, ".bash_functions_d", "tui")
	_ = os.MkdirAll(auditDir, 0o700)
	auditPath := filepath.Join(auditDir, "agent_audit.log")

	// load audit if exists
	auditContent := ""
	if b, err := ioutil.ReadFile(auditPath); err == nil { auditContent = string(b) }

	m := model{list: l, agentsList: agList, requestsList: reqList, vp: vp, ti: ti, ta: ta, cwd: cwd, tabs: tabs, active: 0, layout: LayoutSingle, mdTheme: "dark", editorFile: "", auditPath: auditPath, auditContent: auditContent, requestsPath: requestsPath, pluginsList: plList}
	return m
}

func listItemsFromDir(dir string) []list.Item {
	files, err := ioutil.ReadDir(dir)
	if err != nil { return []list.Item{} }
	out := make([]list.Item, 0, len(files))
	for _, fi := range files {
		out = append(out, fileItem{name: fi.Name(), path: filepath.Join(dir, fi.Name()), isDir: fi.IsDir()})
	}
	return out
}

func runExternalViewer(cmd string, args ...string) error {
	c := exec.Command(cmd, args...)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	return c.Run()
}

// loadAgents reads the agents manifest and returns list.Items for the agent list
func loadAgents() []list.Item {
	home, _ := os.UserHomeDir()
	manifest := filepath.Join(home, "bash_functions.d", "40-agents", "manifest.json")
	b, err := ioutil.ReadFile(manifest)
	if err != nil { return []list.Item{} }
	var data struct{
		Agents []struct{ Name string `json:"name"`; Desc string `json:"desc"` } `json:"agents"`
		Crews []struct{ Name string `json:"name"`; Desc string `json:"desc"` } `json:"crews"`
	}
	if err := json.Unmarshal(b, &data); err != nil { return []list.Item{} }
	out := []list.Item{}
	for _, a := range data.Agents {
		out = append(out, agentItem{name: a.Name, desc: a.Desc})
	}
	for _, c := range data.Crews {
		out = append(out, agentItem{name: c.Name, desc: c.Desc})
	}
	return out
}

func loadRequests(path string) []list.Item {
	b, err := ioutil.ReadFile(path)
	if err != nil { return []list.Item{} }
	var arr []requestItem
	if err := json.Unmarshal(b, &arr); err != nil { return []list.Item{} }
	out := []list.Item{}
	for _, r := range arr { out = append(out, r) }
	return out
}

func loadPlugins() []list.Item {
	home, _ := os.UserHomeDir()
	plugDir := filepath.Join(home, ".bash_functions.d", "plugins")
	items := []list.Item{}
	files, err := ioutil.ReadDir(plugDir)
	if err!=nil { return items }
	for _, fi := range files {
		if !fi.IsDir() { continue }
		name := fi.Name()
		enabled := "disabled"
		if _, err := os.Lstat(filepath.Join(plugDir, "enabled", name)); err==nil { enabled = "enabled" }
		items = append(items, agentItem{name: name, desc: enabled})
	}
	return items
}

// runAgent executes the agent_runner.sh with the given agent name. execFlag controls whether to pass --exec
func (m *model) runAgent(agent string, execFlag bool) (string, int, error) {
	home, _ := os.UserHomeDir()
	script := filepath.Join(home, "bash_functions.d", "40-agents", "agent_runner.sh")
	// prepend source of SSH_PLUGIN_ENV if set
	pluginEnv := os.Getenv("SSH_PLUGIN_ENV")
	var cmd *exec.Cmd
	if execFlag {
		if pluginEnv!="" {
			cmd = exec.Command("/bin/sh", "-c", fmt.Sprintf("[ -f '%s' ] && . '%s'; %s %s --exec", pluginEnv, pluginEnv, script, shellEscape(agent)))
		} else {
			cmd = exec.Command("/bin/sh", "-c", fmt.Sprintf("%s %s --exec", script, shellEscape(agent)))
		}
	} else {
		if pluginEnv!="" {
			cmd = exec.Command("/bin/sh", "-c", fmt.Sprintf("[ -f '%s' ] && . '%s'; %s %s", pluginEnv, pluginEnv, script, shellEscape(agent)))
		} else {
			cmd = exec.Command("/bin/sh", "-c", fmt.Sprintf("%s %s", script, shellEscape(agent)))
		}
	}
	cmd.Env = os.Environ()
	out, err := cmd.CombinedOutput()
	exitCode := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else { exitCode = 1 }
	}
	return string(out), exitCode, err
}

func shellEscape(s string) string { return strings.ReplaceAll(s, "'", "'\\''") }

func (m model) Init() tea.Cmd { return nil }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
				return m, tea.Quit
		case "tab":
				m.active = (m.active+1) % len(m.tabs)
				m.status = ""
				return m, nil
		case "shift+tab":
				m.active = (m.active-1+len(m.tabs))%len(m.tabs)
				return m, nil
		case "l":
				// cycle layout
				m.layout = (m.layout + 1) % 3
				m.status = fmt.Sprintf("layout=%d", m.layout)
				return m, nil
		case "t":
				// toggle markdown theme
				if m.mdTheme=="dark" { m.mdTheme = "light" } else { m.mdTheme = "dark" }
				m.status = "theme=" + m.mdTheme
				return m, nil
		case "1","2","3","4","5","6","7":
				i := int(msg.String()[0]-'1')
				if i>=0 && i<len(m.tabs) { m.active = i }
				return m, nil
		}

		// Files tab handling
		if m.tabs[m.active] == "Files" {
			if msg.String() == "enter" {
				sel, ok := m.list.SelectedItem().(fileItem)
				if !ok { return m, nil }
				if sel.isDir {
					m.cwd = sel.path
					m.list.SetItems(listItemsFromDir(m.cwd))
					m.list.Title = "Files: " + m.cwd
					m.status = "cd " + m.cwd
					return m, nil
				}
				ext := strings.ToLower(filepath.Ext(sel.name))
				if ext==".md" || ext==".markdown" {
					content, _ := ioutil.ReadFile(sel.path)
					r, _ := glamour.Render(string(content), m.mdTheme)
					m.vp.SetContent(r)
					m.active = 2 // Preview (note Agents at index 1)
					m.status = "preview: " + sel.name
					return m, nil
				}
				m.status = "press 'e' to open in $EDITOR, 'E' to open in embedded editor, or 'p' to print"
				return m, nil
			}
			if msg.String() == "e" {
				sel, ok := m.list.SelectedItem().(fileItem)
				if !ok { return m, nil }
				editor := os.Getenv("EDITOR")
				if editor=="" { editor = "vi" }
				_ = runExternalViewer(editor, sel.path)
				return m, nil
			}
			// open in embedded editor
			if msg.String() == "E" {
				sel, ok := m.list.SelectedItem().(fileItem)
				if !ok || sel.isDir { m.status = "no file selected for editor"; return m, nil }
				b, err := ioutil.ReadFile(sel.path)
				if err!=nil { m.status = "failed to read file for editor"; return m, nil }
				m.ta.SetValue(string(b))
				m.editorFile = sel.path
				m.active = 3 // Editor tab (Files=0, Agents=1, Preview=2, Editor=3)
				m.status = "editing: " + sel.name
				return m, nil
			}
			if msg.String() == "p" {
				sel, ok := m.list.SelectedItem().(fileItem)
				if !ok { return m, nil }
				b, _ := ioutil.ReadFile(sel.path)
				m.vp.SetContent(string(b))
				m.active = 2
				return m, nil
			}
		}

		// Agents tab handling
		if m.tabs[m.active] == "Agents" {
			if msg.String() == "enter" {
				// inspect agent
				sel, ok := m.agentsList.SelectedItem().(agentItem)
				if !ok { return m, nil }
				m.vp.SetContent(fmt.Sprintf("Agent: %s\n\n%s", sel.name, sel.desc))
				return m, nil
			}
			// r = dry-run, R = exec
			if msg.String() == "r" || msg.String() == "R" {
				sel, ok := m.agentsList.SelectedItem().(agentItem)
				if !ok { return m, nil }
				execFlag := msg.String() == "R"
				// check permissions: allowed execs list from env
				if execFlag {
					allowed := os.Getenv("SSH_ALLOWED_EXEC")
					if allowed == "" {
						m.status = "execution not allowed for this user"
						m.vp.SetContent("Execution not allowed for this user (no SSH_ALLOWED_EXEC)")
						return m, nil
					}
					allowedList := strings.Split(allowed, ",")
					ok := false
					for _, a := range allowedList { if a == sel.name { ok = true; break } }
					if !ok {
						m.status = "user not permitted to exec this agent"
						m.vp.SetContent("User not permitted to exec this agent")
						return m, nil
					}
				}
				out, code, err := m.runAgent(sel.name, execFlag)
				// write audit
				audit := fmt.Sprintf("%s\tagent=%s\texec=%v\texit=%d\terror=%v\n", time.Now().Format(time.RFC3339), sel.name, execFlag, code, err)
				ioutil.WriteFile(m.auditPath, []byte(audit), 0o600) // overwrite simple log; append below
				// append to file
				f, _ := os.OpenFile(m.auditPath, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0o600)
				if f != nil {
					defer f.Close()
					f.WriteString(audit)
				}
				m.vp.SetContent(out)
				m.status = fmt.Sprintf("ran agent %s (exec=%v) code=%d", sel.name, execFlag, code)
				return m, nil
			}
			return m, nil
		}

		// Requests tab handling
		if m.tabs[m.active] == "Requests" {
			if msg.String() == "r" {
				m.requestsList.SetItems(loadRequests(m.requestsPath))
				m.status = "refreshed requests"
				return m, nil
			}
			if msg.String() == "enter" {
				sel, ok := m.requestsList.SelectedItem().(requestItem)
				if ok { m.vp.SetContent(fmt.Sprintf("Request %s: %s by %s\nNotes: %s", sel.ID, sel.Agent, sel.User, sel.Notes)) }
				return m, nil
			}
			// Approve (A) and Deny (D) - only if SSH_IS_ADMIN=1
			if msg.String() == "A" || msg.String() == "D" {
				sel, ok := m.requestsList.SelectedItem().(requestItem)
				if !ok { return m, nil }
				isAdmin := os.Getenv("SSH_IS_ADMIN") == "1"
				if !isAdmin {
					m.status = "admin privileges required"
					m.vp.SetContent("Admin privileges required to approve/deny requests")
					return m, nil
				}
				if msg.String() == "D" {
					_ = m.markRequest(sel.ID, "denied", "denied by admin")
					m.requestsList.SetItems(loadRequests(m.requestsPath))
					m.vp.SetContent("Request denied")
					return m, nil
				}
				// Approve: run the agent with exec
				out, code, err := m.runAgent(sel.Agent, true)
				_ = m.markRequest(sel.ID, "approved", fmt.Sprintf("exit=%d err=%v", code, err))
				m.requestsList.SetItems(loadRequests(m.requestsPath))
				m.vp.SetContent(out)
				m.status = fmt.Sprintf("approved request %s", sel.ID)
				return m, nil
			}
			return m, nil
		}

		// Audit tab handling
		if m.tabs[m.active] == "Audit" {
			if msg.String() == "u" {
				m.refreshAudit()
				m.vp.SetContent(m.auditContent)
				m.status = "refreshed audit"
				return m, nil
			}
		}

		// Editor tab handling
		if m.tabs[m.active] == "Editor" {
			// handle save (ctrl+s) and quit editor (ctrl+q)
			if msg.String() == "ctrl+s" {
				if m.editorFile == "" {
					m.status = "no file path to save to (open a file from Files with 'E')"
					return m, nil
				}
				err := ioutil.WriteFile(m.editorFile, []byte(m.ta.Value()), 0o600)
				if err!=nil { m.status = "save failed: " + err.Error() } else { m.status = "saved: " + m.editorFile }
				return m, nil
			}
			if msg.String() == "ctrl+q" {
				// exit editor back to Files
				m.active = 0
				m.status = "exited editor"
				return m, nil
			}
			// otherwise, pass the key to textarea for editing
			var cmd tea.Cmd
			m.ta, cmd = m.ta.Update(msg)
			return m, cmd
		}

		// Shell tab handling
		if m.tabs[m.active] == "Shell" {
			if msg.String() == "enter" {
				cmdStr := strings.TrimSpace(m.ti.Value())
				if cmdStr=="" { return m, nil }
				m.status = "running: " + cmdStr
				m.ti.SetValue("")
				pluginEnv := os.Getenv("SSH_PLUGIN_ENV")
				var shellCmd *exec.Cmd
				if pluginEnv!="" {
					shellCmd = exec.Command("/bin/sh", "-c", fmt.Sprintf("[ -f '%s' ] && . '%s'; %s", pluginEnv, pluginEnv, cmdStr))
				} else {
					shellCmd = exec.Command("/bin/sh", "-c", cmdStr)
				}
				out, err := shellCmd.CombinedOutput()
				if err!=nil { m.vp.SetContent(fmt.Sprintf("(error: %v)\n%s", err, string(out))) }
				m.vp.SetContent(string(out))
				return m, nil
			}
			var cmd tea.Cmd
			m.ti, cmd = m.ti.Update(msg)
			return m, cmd
		}

	case tea.WindowSizeMsg:
		m.vp.Width = msg.Width - 32
		m.vp.Height = msg.Height - 8
		m.list.SetSize(30, msg.Height-8)
		m.ta.SetWidth(msg.Width-34)
		m.ta.SetHeight(msg.Height-12)
		m.agentsList.SetSize(40, msg.Height-8)
		m.requestsList.SetSize(60, msg.Height-8)
		return m, nil
	}

	// default: let list handle keys in Files tab
	if m.tabs[m.active] == "Files" {
		var cmd tea.Cmd
		m.list, cmd = m.list.Update(msg)
		return m, cmd
	}
	if m.tabs[m.active] == "Agents" {
		var cmd tea.Cmd
		m.agentsList, cmd = m.agentsList.Update(msg)
		return m, cmd
	}
	if m.tabs[m.active] == "Requests" {
		var cmd tea.Cmd
		m.requestsList, cmd = m.requestsList.Update(msg)
		return m, cmd
	}
	if m.tabs[m.active] == "Plugins" {
		var cmd tea.Cmd
		m.pluginsList, cmd = m.pluginsList.Update(msg)
		return m, cmd
	}

	return m, nil
}

func renderSplit(left, right string, width int) string {
	leftBox := boxStyle.Width(30).Render(left)
	rightBox := boxStyle.Width(width-32).Render(right)
	return lipgloss.JoinHorizontal(lipgloss.Top, leftBox, rightBox)
}

func (m model) View() string {
	// tabs row
	var b strings.Builder
	for i, t := range m.tabs {
		if i==m.active {
			b.WriteString(activeTabStyle.Render(fmt.Sprintf(" %d:%s ", i+1, t)))
		} else {
			b.WriteString(tabStyle.Render(fmt.Sprintf(" %d:%s ", i+1, t)))
		}
	}
	b.WriteString("\n\n")

	// content
	var mainContent string
	switch m.tabs[m.active] {
	case "Files":
		mainContent = m.list.View()
	case "Agents":
		mainContent = m.agentsList.View()
	case "Requests":
		mainContent = m.requestsList.View()
	case "Audit":
		mainContent = m.auditContent
	case "Plugins":
		mainContent = m.pluginsList.View()
	case "Preview":
		mainContent = m.vp.View()
	case "Editor":
		mainContent = m.ta.View()
	case "Shell":
		mainContent = m.vp.View() + "\n" + m.ti.View()
	case "Image":
		mainContent = "Image tab: select an image in Files and press 'o' to view with 'viu' or 'xdg-open'.\n"
	case "YouTube":
		mainContent = "YouTube tab: select a file containing a video URL and press 'o' to play with mpv.\n"
	}

	// layout rendering
	switch m.layout {
	case LayoutSingle:
		b.WriteString(mainContent)
	case LayoutVerticalSplit:
		left := m.list.View()
		right := m.vp.View()
		b.WriteString(renderSplit(left, right, width))
	case LayoutHorizontalSplit:
		b.WriteString(m.list.View())
		b.WriteString("\n--\n")
		b.WriteString(m.vp.View())
	}

	b.WriteString("\n")
	b.WriteString(helpStyle.Render("q: quit • tab: next pane • l: cycle layout • t: toggle md theme • 1-7: switch tabs • enter: open/preview • e: edit • o: open external • E: edit in-TUI • r: dry-run agent • R: run agent (exec) • Ctrl+S: save • Ctrl+Q: quit editor"))
	if m.status!="" { b.WriteString("\n" + helpStyle.Render("status: ") + " " + m.status) }
	return b.String()
}

func main() {
	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if err := p.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "Error starting TUI: %v\n", err)
		os.Exit(1)
	}
}
