# Odoo Remember Feedback Skill

**Purpose:** Capture insights, patterns, and best practices discovered during Odoo module development and store them in persistent repository memory.

---

## What to Capture

This skill helps preserve team knowledge by recording:

### 1. **Common Patterns & Best Practices**
- Proven coding patterns that work well across modules (e.g., "Always use Command API for m2m operations in tests")
- Reusable field definition patterns (e.g., "Add `index=True` to any partner_id field used in searches")
- Model inheritance chains that have proven effective
- Compute method patterns for specific use cases

### 2. **Custom Team Conventions**
- Naming conventions beyond OCA standards (e.g., "Use `_confirmation_` prefix for workflow state changes")
- Module interdependency patterns (e.g., "Always provide depends=[] for optional integrations")
- Security group naming schemes
- Demo data patterns specific to your business

### 3. **Gotchas & Lessons Learned**
- Bugs or inefficiencies discovered and how to avoid them (e.g., "String field computations without NULL coalescing cause test failures")
- Framework quirks in Odoo 18.0+ that cost debugging time
- Common migration pitfalls (e.g., "Computed fields with `store=True` must have `compute=` methods in new modules")
- Environment-specific gotchas (e.g., "Test database cleanup requires explicit flush in setUp()")

### 4. **Performance Patterns**
- Query patterns that avoid N+1 problems
- Efficient context usage patterns
- Domain expressions that scale well
- Batching strategies for large datasets

---

## How to Use

### Quick Capture
```
@odoo /remember-pattern "use float_is_zero() for all float comparisons in accounting modules"
```

### In Conversation
While working on a module, mention patterns as they are discovered:
```
@odoo I just realized Command.create() is much more reliable than direct create() 
for many-to-many operations in tests. Should we remember this?
```

The skill will:
1. Validate the pattern is specific and actionable
2. Extract the core insight
3. Add context (when discovered, which modules)
4. Store in `/memories/repo/odoo-patterns.md`
5. Load automatically in future Odoo conversations

---

## Pattern Storage Format

Patterns are stored in `/memories/repo/odoo-patterns.md` as categorized entries:

```markdown
# Odoo Patterns & Best Practices

## Testing Patterns
- **Command API for collections**: Always use `Command.create([...])` instead of direct `.create()` for m2m/o2m operations. It handles field updates more reliably.
- **setUp vs setUpClass**: Use `setUpClass` for expensive operations (company creation), `setUp` for per-test data mutations.

## Field Definition Patterns
- **Partner search fields**: Add `index=True` to any `partner_id`, `employee_id` field used in list views or domains
- **Field dependencies**: Use explicit `@depends('field_id.related_field')` with full paths for nested dependencies

## Gotchas
- **String field NULL handling**: String computations without `coalesce()` cause division-by-zero in tests; always wrap concatenations
- **Computed field storing**: `store=True` on computed fields requires the compute method to persist; avoid lazy computation
```

---

## Memory Scope

**What's stored:** Patterns specific to this c4a8 Odoo workspace — conventions, lessons learned, and patterns that apply across modules here.

**Who accesses it:** All `@odoo` agents and skills. Patterns are automatically loaded into context for module development, testing, and validation work.

**Update frequency:** Continuously — new patterns are added as they're discovered.

**Retention:** Indefinite — this becomes the institutional knowledge base for Odoo development in your workspace.

---

## Examples

### ✅ Good Pattern to Capture
```
use float_is_zero() for all float comparisons in accounting modules, 
not == or >, to handle floating point precision correctly
```

### ✅ Good Gotcha to Capture
```
String field computations sometimes need coalesce() to avoid NULL 
concatenations in Odoo 18.0+ that cause test failures
```

### ❌ Too Generic (Skip)
```
Write good tests
```

### ❌ Too Module-Specific (Skip)
```
In equipment_confirmation, we use _confirmation_date to track state
```

---

## Related Commands

| Command | Purpose |
|---------|---------|
| `@odoo /remember-pattern "..."` | Capture a new pattern |
| `@odoo What patterns exist for X?` | Query existing patterns (agent searches `/memories/repo/odoo-patterns.md`) |
| Manual edit | Update or organize patterns directly in `/memories/repo/odoo-patterns.md` |

---

## Implementation Notes

When the skill is invoked:

1. **Parse the input** — extract the core pattern/gotcha/convention
2. **Categorize** — determine if it's testing, field definition, security, performance, etc.
3. **Validate** — check that it's reusable, not too specific to one module
4. **Store** — append to `/memories/repo/odoo-patterns.md` under the appropriate section
5. **Confirm** — show the user what was saved and where it'sstored
6. **Load for future use** — agent context automatically includes patterns in subsequent conversations

---

## Integration with @odoo Agent

The `@odoo` agent automatically:
- Loads patterns from `/memories/repo/odoo-patterns.md` at startup
- References patterns when writing models, tests, and documentation
- Suggests relevant patterns when it detects similar code
- Uses patterns to inform validation and code review

Example agent behavior:
```
User: Write a test for the payment confirmation flow
Agent: [Loads testing patterns from memory]
I'll use the Command API pattern for m2m operations and setUpClass for expensive setup.
```

---

## FAQ

**Q: Can I capture patterns from other projects?**  
A: Yes, if they apply to your c4a8 modules. Prefix with context: "From OCA contract repo: ..."

**Q: What if a pattern becomes outdated?**  
A: Update or delete it in `/memories/repo/odoo-patterns.md`. The agent will use the current version.

**Q: How do patterns interact with the validation skill?**  
A: Validation checks against OCA standards + team patterns. If a pattern contradicts OCA guidelines, validation flags it.

**Q: Can I share patterns across workspaces?**  
A: Not automatically — patterns are repo-scoped. To share, export from `/memories/repo/odoo-patterns.md` and copy to another workspace.
