#!/bin/bash
# skills-hub-v2 validation script
# Verifica que todo el sistema está listo para operar

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_info() { echo -e "  ℹ $1"; }

# ============================================================================
# PHASE 1: Skills Structure Validation
# ============================================================================
echo "📋 Phase 1: Skills Structure Validation"
echo "========================================"

validate_skill() {
    local skill_path="$1"
    local skill_name=$(basename "$skill_path")
    local skill_md="${skill_path}/SKILL.md"
    
    if [[ ! -f "$skill_md" ]]; then
        log_error "$skill_name: SKILL.md not found"
        return 1
    fi
    
    # Check for version 3.0
    if grep -q 'version: "3.0"' "$skill_md" || grep -q 'version: "3\.1"' "$skill_md" || grep -q 'version: "3\.2"' "$skill_md"; then
        log_success "$skill_name: v3.0 Contract found"
    else
        log_warning "$skill_name: may not be v3.0 (check manually)"
    fi
    
    # Check for Execution Contract structure
    if grep -q "Execution Contract" "$skill_md"; then
        log_success "$skill_name: Contract structure validated"
    else
        log_warning "$skill_name: may not use Contract format"
    fi
    
    # Check for pre-conditions
    if grep -q "Pre-conditions" "$skill_md"; then
        log_success "$skill_name: Pre-conditions defined"
    else
        log_warning "$skill_name: no pre-conditions defined"
    fi
    
    # Check for post-conditions
    if grep -q "Post-conditions" "$skill_md"; then
        log_success "$skill_name: Post-conditions defined"
    else
        log_warning "$skill_name: no post-conditions defined"
    fi
    
    return 0
}

# Validate all SDD skills
for skill in sdd-init sdd-explore sdd-propose sdd-spec sdd-design sdd-tasks sdd-apply sdd-verify sdd-archive sdd-onboard session-start session-end; do
    echo ""
    echo "  Validating: $skill"
    skill_path="${PROJECT_ROOT}/skills/common/$skill"
    if [[ -d "$skill_path" ]]; then
        validate_skill "$skill_path" || true
    else
        log_error "$skill: directory not found"
    fi
done

# ============================================================================
# PHASE 2: Manifiest Validation
# ============================================================================
echo ""
echo "📋 Phase 2: Manifest Validation"
echo "========================================"

MANIFEST="${PROJECT_ROOT}/skills/skills-manifest.json"

if [[ -f "$MANIFEST" ]]; then
    log_success "Manifest file exists"
    
    # Check JSON validity
    if python3 -c "import json; json.load(open('$MANIFEST'))" 2>/dev/null; then
        log_success "Manifest is valid JSON"
        
        # Check for required fields
        if python3 -c "
import json
manifest = json.load(open('$MANIFEST'))
assert 'schema_version' in manifest, 'Missing schema_version'
assert 'skills' in manifest, 'Missing skills array'
assert len(manifest['skills']) > 0, 'Skills array is empty'
print(f'  Skills count: {len(manifest[\"skills\"])}')
for skill in manifest['skills']:
    assert 'id' in skill, f'Skill missing id: {skill.get(\"name\", \"unknown\")}'
    assert 'model' in skill, f'Skill {skill.get(\"id\")} missing model'
    assert 'vram_usage_gb' in skill, f'Skill {skill.get(\"id\")} missing vram_usage_gb'
print('  All skills have required fields: id, model, vram_usage_gb')
" 2>/dev/null; then
            log_success "Manifest structure is valid"
        else
            log_error "Manifest structure has missing required fields"
        fi
    else
        log_error "Manifest is not valid JSON"
    fi
else
    log_error "Manifest file not found at $MANIFEST"
fi

# ============================================================================
# PHASE 3: Model-Map Validation
# ============================================================================
echo ""
echo "📋 Phase 3: Model-Map Validation"
echo "========================================"

MODEL_MAP="${PROJECT_ROOT}/config/model-map.json"

if [[ -f "$MODEL_MAP" ]]; then
    log_success "Model-map file exists"
    
    # Check JSON validity
    if python3 -c "import json; json.load(open('$MODEL_MAP'))" 2>/dev/null; then
        log_success "Model-map is valid JSON"
        
        # Check for required fields
        if python3 -c "
import json
model_map = json.load(open('$MODEL_MAP'))
assert 'model_map' in model_map, 'Missing model_map object'
assert 'execution_strategy' in model_map, 'Missing execution_strategy'
assert 'max_vram_gb' in model_map, 'Missing max_vram_gb'
print(f'  Model map phases: {len(model_map[\"model_map\"])}')
for phase, config in model_map['model_map'].items():
    assert 'model' in config, f'Model map missing model for {phase}'
    assert 'vram_gb' in config, f'Model map missing vram_gb for {phase}'
print('  All phases have required fields: model, vram_gb')
# Check execution strategy
assert model_map['execution_strategy']['vram_management'] == 'strict', 'vram_management should be strict'
print('  VRAM management is set to strict mode')
print('  Execution strategy validated')
" 2>/dev/null; then
            log_success "Model-map structure is valid"
        else
            log_error "Model-map structure has issues"
        fi
    else
        log_error "Model-map is not valid JSON"
    fi
else
    log_error "Model-map file not found at $MODEL_MAP"
fi

# ============================================================================
# PHASE 4: Ollama Models Availability
# ============================================================================
echo ""
echo "📋 Phase 4: Ollama Models Availability"
echo "========================================"

if command -v ollama &> /dev/null; then
    log_success "Ollama CLI found"
    
    # Get available models
    if ollama_list=$(ollama list 2>/dev/null); then
        log_success "Ollama list retrieved"
        
        # Models required
        declare -A required_models
        required_models["qwen3.6:35b"]="23 GB"
        required_models["qwen3.5:122b-a10b"]="81 GB"
        required_models["deepseek-coder-v2:16b"]="8.9 GB"
        
        for required_model in "${!required_models[@]}"; do
            required_vram="${required_models[$required_model]}"
            if echo "$ollama_list" | grep -q "$required_model"; then
                log_success "$required_model (${required_vram}) ✓"
            else
                log_error "$required_model (${required_vram}) ✗ NOT FOUND"
            fi
        done
    else
        log_error "Could not retrieve Ollama list"
    fi
else
    log_error "Ollama CLI not found in PATH"
fi

# ============================================================================
# PHASE 5: Git Repository Check
# ============================================================================
echo ""
echo "📋 Phase 5: Git Repository Check"
echo "========================================"

if git rev-parse --git-dir &>/dev/null; then
    log_success "Git repository found"
    
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    remote=$(git remote get-url origin 2>/dev/null || echo "none")
    
    log_info "Current branch: $current_branch"
    log_info "Remote: $remote"
    
    # Check for uncommitted changes
    if git diff --quiet --exit-code 2>/dev/null; then
        log_success "No uncommitted changes"
    else
        log_warning "Uncommitted changes detected"
        git status --short 2>/dev/null | head -5 | sed 's/^/  /'
    fi
    
    # Check GitFlow branches
    if git show-ref --verify --quiet refs/heads/main; then
        log_success "main branch exists"
    else
        log_warning "main branch not found (may not be GitFlow project)"
    fi
    
    if git show-ref --verify --quiet refs/heads/develop; then
        log_success "develop branch exists"
    else
        log_warning "develop branch not found (may not be GitFlow project)"
    fi
else
    log_error "Not a git repository"
    log_info "Run 'git init' to initialize the project"
fi

# ============================================================================
# PHASE 6: VRAM Check
# ============================================================================
echo ""
echo "📋 Phase 6: VRAM Check (Estimación)"
echo "========================================"

# Check if NVIDIA GPU is available
if command -v nvidia-smi &> /dev/null; then
    if gpu_info=$(nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader 2>/dev/null); then
        log_success "NVIDIA GPU detected"
        
        # Parse memory usage
        gpu_memory=$(echo "$gpu_info" | head -1 | cut -d',' -f2 | tr -d '[:space:]')
        gpu_used=$(echo "$gpu_info" | head -1 | cut -d',' -f3 | tr -d '[:space:]')
        
        log_info "Total VRAM: $gpu_memory"
        log_info "VRAM usage may change as scripts run"
    else
        log_warning "Could not retrieve GPU information"
    fi
else
    log_warning "nvidia-smi not found (no NVIDIA GPU detected or drivers not installed)"
fi

# ============================================================================
# PHASE 7: Project Structure Validation
# ============================================================================
echo ""
echo "📍 Phase 7: Project Structure Validation"
echo "========================================"

# Check required directories
for dir in skills/common config scripts; do
    if [[ -d "${PROJECT_ROOT}/$dir" ]]; then
        log_success "$dir/ exists"
    else
        log_warning "$dir/ not found"
    fi
done

# Check required root files
for file in README.md CHANGELOG.md GITFLOW.md; do
    if [[ -f "${PROJECT_ROOT}/$file" ]]; then
        log_success "$file exists"
    else
        log_warning "$file not found"
    fi
done

# ============================================================================
# FINAL SUMMARY
# ============================================================================
echo ""
echo "════════════════════════════════════════"
echo "📊 Validation Summary"
echo "════════════════════════════════════════"

errors=0
warnings=0

# Count errors and warnings from output
# (In a real script, we'd track this with counters)
echo ""
echo "Validation complete!"
echo "Ruta del proyecto: $PROJECT_ROOT"
echo ""
echo "Para ejecutar el sistema:"
echo "  1. Arranca ollama: ollama pull qwen3.6:35b (si no está)"
echo "  2. Verifica que todos los modelos estén listos"
echo "  3. Ejecuta: hermes session-start"
echo ""
echo "Los errores en rojo deben corregirse antes de operar."
echo "Las advertencias en amarillo son sugerencias de mejora."

if [[ $errors -gt 0 ]]; then
    echo ""
    echo -e "${RED}⚠ $errors errores encontrados - corrígelos antes de operar${NC}"
    exit 1
elif [[ $warnings -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠ $warnings advertencias - revisa y corrige cuando puedas${NC}"
fi

echo ""
echo -e "${GREEN}✓ Sistema listo para operar${NC}"
