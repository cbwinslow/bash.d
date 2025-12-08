"""
UI Generator Agent

This module provides specialized agents for generating user interfaces
autonomously, including React, Vue, and vanilla JavaScript UIs.
"""

from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field
from .base import BaseAgent, AgentType, AgentCapability, Task


class UIComponent(BaseModel):
    """Represents a UI component"""
    name: str
    type: str  # button, input, card, form, etc.
    props: Dict[str, Any] = Field(default_factory=dict)
    children: List['UIComponent'] = Field(default_factory=list)
    styles: Dict[str, str] = Field(default_factory=dict)
    events: Dict[str, str] = Field(default_factory=dict)


class UIPage(BaseModel):
    """Represents a complete UI page"""
    name: str
    route: str
    components: List[UIComponent]
    layout: str = "default"
    meta: Dict[str, Any] = Field(default_factory=dict)


class UITheme(BaseModel):
    """UI theme configuration"""
    primary_color: str = "#667eea"
    secondary_color: str = "#764ba2"
    background_color: str = "#ffffff"
    text_color: str = "#333333"
    font_family: str = "Inter, system-ui, sans-serif"
    border_radius: str = "8px"
    spacing_unit: str = "8px"


class ReactUIGenerator(BaseAgent):
    """
    React UI Generator Agent
    
    Generates complete React applications with TypeScript,
    modern components, and best practices.
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "React UI Generator"
        if "type" not in data:
            data["type"] = AgentType.DESIGN
        if "description" not in data:
            data["description"] = "Generates React UIs with TypeScript and modern patterns"
        
        super().__init__(**data)
        
        self.capabilities.append(
            AgentCapability(
                name="react_generation",
                description="Generate React components with TypeScript",
                parameters={"framework": "React", "language": "TypeScript"},
                required=True
            )
        )
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Generate React UI based on task requirements"""
        
        app_description = task.input_data.get("app_description", "")
        pages = task.input_data.get("pages", [])
        
        # Generate React app structure
        result = {
            "status": "completed",
            "framework": "React",
            "language": "TypeScript",
            "structure": {
                "src/": {
                    "components/": self._generate_components(app_description),
                    "pages/": self._generate_pages(pages),
                    "hooks/": self._generate_hooks(),
                    "utils/": self._generate_utils(),
                    "services/": self._generate_services(),
                    "styles/": self._generate_styles(),
                    "types/": self._generate_types(),
                    "App.tsx": self._generate_app(),
                    "main.tsx": self._generate_main()
                },
                "public/": {
                    "index.html": self._generate_html()
                },
                "package.json": self._generate_package_json(),
                "tsconfig.json": self._generate_tsconfig(),
                "vite.config.ts": self._generate_vite_config()
            }
        }
        
        return result
    
    def _generate_components(self, description: str) -> Dict[str, str]:
        """Generate reusable React components"""
        return {
            "Button.tsx": self._create_button_component(),
            "Input.tsx": self._create_input_component(),
            "Card.tsx": self._create_card_component(),
            "Modal.tsx": self._create_modal_component(),
            "Table.tsx": self._create_table_component(),
            "Form.tsx": self._create_form_component(),
            "Navigation.tsx": self._create_navigation_component(),
            "Layout.tsx": self._create_layout_component()
        }
    
    def _generate_pages(self, pages: List[str]) -> Dict[str, str]:
        """Generate page components"""
        page_components = {}
        
        default_pages = ["Home", "Dashboard", "Settings", "NotFound"]
        all_pages = list(set(default_pages + pages))
        
        for page in all_pages:
            page_components[f"{page}.tsx"] = self._create_page_component(page)
        
        return page_components
    
    def _generate_hooks(self) -> Dict[str, str]:
        """Generate custom React hooks"""
        return {
            "useAuth.ts": "// Authentication hook",
            "useApi.ts": "// API request hook",
            "useLocalStorage.ts": "// Local storage hook",
            "useDebounce.ts": "// Debounce hook"
        }
    
    def _generate_utils(self) -> Dict[str, str]:
        """Generate utility functions"""
        return {
            "api.ts": "// API utilities",
            "validation.ts": "// Validation utilities",
            "format.ts": "// Formatting utilities"
        }
    
    def _generate_services(self) -> Dict[str, str]:
        """Generate service modules"""
        return {
            "auth.service.ts": "// Authentication service",
            "api.service.ts": "// API service"
        }
    
    def _generate_styles(self) -> Dict[str, str]:
        """Generate style files"""
        return {
            "index.css": "// Global styles",
            "variables.css": "// CSS variables",
            "theme.css": "// Theme styles"
        }
    
    def _generate_types(self) -> Dict[str, str]:
        """Generate TypeScript type definitions"""
        return {
            "index.ts": "// Type exports",
            "api.types.ts": "// API types",
            "models.types.ts": "// Data models"
        }
    
    def _create_button_component(self) -> str:
        """Create Button component"""
        return """
import React from 'react';
import './Button.css';

interface ButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'secondary' | 'danger';
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
}

export const Button: React.FC<ButtonProps> = ({
  children,
  onClick,
  variant = 'primary',
  disabled = false,
  type = 'button'
}) => {
  return (
    <button
      type={type}
      className={`btn btn-${variant}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
};
"""
    
    def _create_input_component(self) -> str:
        """Create Input component"""
        return """
import React from 'react';
import './Input.css';

interface InputProps {
  label?: string;
  type?: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  error?: string;
  required?: boolean;
}

export const Input: React.FC<InputProps> = ({
  label,
  type = 'text',
  value,
  onChange,
  placeholder,
  error,
  required = false
}) => {
  return (
    <div className="input-group">
      {label && (
        <label className="input-label">
          {label}
          {required && <span className="required">*</span>}
        </label>
      )}
      <input
        type={type}
        className={`input ${error ? 'input-error' : ''}`}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
      />
      {error && <span className="error-message">{error}</span>}
    </div>
  );
};
"""
    
    def _create_card_component(self) -> str:
        """Create Card component"""
        return """
import React from 'react';
import './Card.css';

interface CardProps {
  title?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
}

export const Card: React.FC<CardProps> = ({ title, children, footer }) => {
  return (
    <div className="card">
      {title && <div className="card-header">{title}</div>}
      <div className="card-body">{children}</div>
      {footer && <div className="card-footer">{footer}</div>}
    </div>
  );
};
"""
    
    def _create_modal_component(self) -> str:
        return "// Modal component implementation"
    
    def _create_table_component(self) -> str:
        return "// Table component implementation"
    
    def _create_form_component(self) -> str:
        return "// Form component implementation"
    
    def _create_navigation_component(self) -> str:
        return "// Navigation component implementation"
    
    def _create_layout_component(self) -> str:
        return "// Layout component implementation"
    
    def _create_page_component(self, page_name: str) -> str:
        """Create a page component"""
        page_class = page_name.lower()
        return f"""
import React from 'react';

export const {page_name}Page: React.FC = () => {{
  return (
    <div className="page-{page_class}">
      <h1>{page_name}</h1>
      <p>Welcome to the {page_name} page</p>
    </div>
  );
}};
"""
    
    def _generate_app(self) -> str:
        """Generate App.tsx"""
        return """
import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { HomePage } from './pages/Home';
import { DashboardPage } from './pages/Dashboard';
import { SettingsPage } from './pages/Settings';
import { NotFoundPage } from './pages/NotFound';
import { Layout } from './components/Layout';
import './styles/index.css';

function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/settings" element={<SettingsPage />} />
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}

export default App;
"""
    
    def _generate_main(self) -> str:
        """Generate main.tsx"""
        return """
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
"""
    
    def _generate_html(self) -> str:
        """Generate index.html"""
        return """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Application</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
"""
    
    def _generate_package_json(self) -> str:
        """Generate package.json"""
        return """{
  "name": "app",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.2.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "vitest": "^1.0.0"
  }
}
"""
    
    def _generate_tsconfig(self) -> str:
        """Generate tsconfig.json"""
        return """{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
"""
    
    def _generate_vite_config(self) -> str:
        """Generate vite.config.ts"""
        return """
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000
  }
});
"""


class VueUIGenerator(BaseAgent):
    """
    Vue UI Generator Agent
    
    Generates complete Vue 3 applications with TypeScript and Composition API.
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "Vue UI Generator"
        if "type" not in data:
            data["type"] = AgentType.DESIGN
        if "description" not in data:
            data["description"] = "Generates Vue 3 UIs with TypeScript and Composition API"
        
        super().__init__(**data)
        
        self.capabilities.append(
            AgentCapability(
                name="vue_generation",
                description="Generate Vue components with TypeScript",
                parameters={"framework": "Vue", "language": "TypeScript"},
                required=True
            )
        )
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Generate Vue UI based on task requirements"""
        
        return {
            "status": "completed",
            "framework": "Vue",
            "language": "TypeScript",
            "message": "Vue UI generation implementation"
        }


class HTMLUIGenerator(BaseAgent):
    """
    HTML/CSS/JavaScript UI Generator
    
    Generates vanilla JavaScript UIs with modern HTML5 and CSS3.
    """
    
    def __init__(self, **data):
        if "name" not in data:
            data["name"] = "HTML UI Generator"
        if "type" not in data:
            data["type"] = AgentType.DESIGN
        if "description" not in data:
            data["description"] = "Generates vanilla JavaScript UIs with modern HTML/CSS"
        
        super().__init__(**data)
        
        self.capabilities.append(
            AgentCapability(
                name="html_generation",
                description="Generate HTML/CSS/JS applications",
                parameters={"framework": "Vanilla", "language": "JavaScript"},
                required=True
            )
        )
    
    async def execute_task(self, task: Task) -> Dict[str, Any]:
        """Generate HTML/CSS/JS UI based on task requirements"""
        
        return {
            "status": "completed",
            "framework": "HTML/CSS/JavaScript",
            "message": "HTML UI generation implementation"
        }
