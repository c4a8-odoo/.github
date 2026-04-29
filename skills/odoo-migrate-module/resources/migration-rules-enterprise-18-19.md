# Odoo 18.0 → 19.0 Migration Rules

## How to Use
These rules guide migration of custom modules from Odoo 18.0 to 19.0.
Each rule describes a specific breaking change and what action to take.
Rules are based on actual `git diff origin/18.0 origin/19.0` findings.

---

## Rules by Category

### Module Renames

#### Rule: account_auto_transfer_renamed
- **Module**: `account_auto_transfer`
- **Type**: module_rename
- **Old**: `account_auto_transfer` in `depends`
- **New**: `account_transfer`
- **Action**: Replace `'account_auto_transfer'` with `'account_transfer'` in `__manifest__.py` depends.
- **Files affected**: `__manifest__.py`

#### Rule: base_automation_hr_contract_renamed
- **Module**: `base_automation_hr_contract`
- **Type**: module_rename
- **Old**: `base_automation_hr_contract` in `depends`
- **New**: `base_automation_hr`
- **Action**: Replace `'base_automation_hr_contract'` with `'base_automation_hr'` in `__manifest__.py` depends.
- **Files affected**: `__manifest__.py`

#### Rule: hr_contract_sign_renamed
- **Module**: `hr_contract_sign`
- **Type**: module_rename
- **Old**: `hr_contract_sign` in `depends`
- **New**: `hr_sign`
- **Action**: Replace `'hr_contract_sign'` with `'hr_sign'` in `__manifest__.py` depends.
- **Files affected**: `__manifest__.py`

#### Rule: hr_holidays_contract_gantt_renamed
- **Module**: `hr_holidays_contract_gantt`
- **Type**: module_rename
- **Old**: `hr_holidays_contract_gantt` in `depends`
- **New**: `hr_holidays_gantt`
- **Action**: Replace `'hr_holidays_contract_gantt'` with `'hr_holidays_gantt'` in `__manifest__.py` depends.
- **Files affected**: `__manifest__.py`

#### Rule: hr_work_entry_contract_enterprise_renamed
- **Module**: `hr_work_entry_contract_enterprise`
- **Type**: module_rename
- **Old**: `hr_work_entry_contract_enterprise` in `depends`
- **New**: `hr_work_entry_enterprise`
- **Action**: Replace `'hr_work_entry_contract_enterprise'` with `'hr_work_entry_enterprise'` in `__manifest__.py` depends.
- **Files affected**: `__manifest__.py`

#### Rule: hr_work_entry_contract_attendance_renamed
- **Module**: `hr_work_entry_contract_attendance`
- **Type**: module_rename
- **Old**: `hr_work_entry_contract_attendance` in `depends`
- **New**: `hr_work_entry_attendance`
- **Action**: Replace `'hr_work_entry_contract_attendance'` with `'hr_work_entry_attendance'` in `__manifest__.py` depends.
- **Files affected**: `__manifest__.py`

#### Rule: hr_work_entry_contract_planning_renamed
- **Module**: `hr_work_entry_contract_planning`
- **Type**: module_rename
- **Old**: `hr_work_entry_contract_planning` in `depends`
- **New**: `hr_work_entry_planning`
- **Action**: Replace `'hr_work_entry_contract_planning'` with `'hr_work_entry_planning'` in `__manifest__.py` depends.
- **Files affected**: `__manifest__.py`

#### Rule: hr_work_entry_contract_planning_attendance_renamed
- **Module**: `hr_work_entry_contract_planning_attendance`
- **Type**: module_rename
- **Old**: `hr_work_entry_contract_planning_attendance` in `depends`
- **New**: `hr_work_entry_planning_attendance`
- **Action**: Replace `'hr_work_entry_contract_planning_attendance'` with `'hr_work_entry_planning_attendance'` in `__manifest__.py` depends.
- **Files affected**: `__manifest__.py`

#### Rule: planning_contract_renamed
- **Module**: `planning_contract`
- **Type**: module_rename
- **Old**: `planning_contract` in `depends`
- **New**: `planning_attendance`
- **Action**: Replace `'planning_contract'` with `'planning_attendance'` in `__manifest__.py` depends.
- **Files affected**: `__manifest__.py`

---

### Manifest Dependency Changes

#### Rule: accountant_depends_change
- **Module**: `accountant`
- **Type**: manifest_depends_change
- **Old**: `depends: ['account_accountant']`
- **New**: `depends: ['account_reports']`
- **Action**: If your module depends on `accountant` being installed after `account_accountant`, verify install order. Modules that previously needed only `accountant` now get `account_reports` transitively.
- **Files affected**: `__manifest__.py`

#### Rule: account_reports_depends_change
- **Module**: `account_reports`
- **Type**: manifest_depends_change
- **Old**: `depends: ['accountant']`
- **New**: `depends: ['account_accountant']`
- **Action**: If depending on `account_reports`, the full `accountant` app is no longer a prerequisite. Adjust your `depends` accordingly.
- **Files affected**: `__manifest__.py`

#### Rule: account_asset_depends_change
- **Module**: `account_asset`
- **Type**: manifest_depends_change
- **Old**: `depends: ['account_reports']`
- **New**: `depends: ['accountant']`
- **Action**: Update expected dependency chain for modules bridging `account_asset`.
- **Files affected**: `__manifest__.py`

#### Rule: web_studio_depends_change
- **Module**: `web_studio`
- **Type**: manifest_depends_change
- **Old**: `depends: [..., 'web_editor', ...]`
- **New**: `web_editor` removed from depends
- **Action**: If your module depended on `web_studio` to pull in `web_editor`, add `web_editor` explicitly.
- **Files affected**: `__manifest__.py`

#### Rule: sale_subscription_base_automation_removed
- **Module**: `sale_subscription`
- **Type**: manifest_depends_change
- **Old**: `depends: [..., 'base_automation', ...]`
- **New**: `base_automation` removed
- **Action**: If your module bridged `sale_subscription` and automation rules, add `base_automation` explicitly to your own `depends`.
- **Files affected**: `__manifest__.py`

#### Rule: hr_appraisal_depends_change
- **Module**: `hr_appraisal`
- **Type**: manifest_depends_change
- **Old**: `depends: ['hr', 'calendar', 'web_gantt']`
- **New**: `depends: ['calendar', 'hr_gantt']`
- **Action**: `hr_gantt` now encapsulates `hr` + `web_gantt`. Update any module that tried to depend on `hr_appraisal + web_gantt` directly.
- **Files affected**: `__manifest__.py`

#### Rule: hr_holidays_gantt_depends_change
- **Module**: `hr_holidays_gantt`
- **Type**: manifest_depends_change
- **Old**: `depends: ['hr_holidays', 'web_gantt']`
- **New**: `depends: ['hr_holidays', 'hr_gantt']`
- **Action**: If bridging `hr_holidays_gantt`, update your dependency on `web_gantt` to `hr_gantt`.
- **Files affected**: `__manifest__.py`

---

### Test Suite Key Rename (ALL modules)

#### Rule: test_suite_qunit_to_assets_unit_tests
- **Module**: ALL modules
- **Type**: manifest_assets_key_change
- **Old**: `'web.qunit_suite_tests': [...]`
- **New**: `'web.assets_unit_tests': [...]`
- **Action**: In every `__manifest__.py`, rename the key `web.qunit_suite_tests` to `web.assets_unit_tests`. Also rename test file glob patterns to include `.test.js` suffix (e.g., `**/*.test.js`).
- **Files affected**: `__manifest__.py`

#### Rule: test_suite_qunit_mobile_removed
- **Module**: ALL modules with mobile tests
- **Type**: manifest_assets_key_change
- **Old**: `'web.qunit_mobile_suite_tests': [...]`
- **New**: `'web.assets_unit_tests': [...]` (with `.test.js` pattern)
- **Action**: Rename key and update file patterns.
- **Files affected**: `__manifest__.py`

---

### Python Model Changes

#### Rule: timer_sql_constraint_to_models_constraint
- **Module**: `timer`
- **Type**: pattern_change
- **Old**: `_sql_constraints = [('unique_timer', 'UNIQUE(...)', '...')]`
- **New**: `_unique_timer = models.Constraint('UNIQUE(...)', '...')`
- **Action**: If overriding `_sql_constraints` in a module inheriting `timer.timer`, switch to `models.Constraint` class attribute instead.
- **Files affected**: `*.py`

#### Rule: timer_create_timer_method
- **Module**: `timer`
- **Type**: method_change
- **Old**: Inline `self.env['timer.timer'].create({...})` with hardcoded dict
- **New**: Override `_get_timer_vals()` or `_create_timer(vals)`
- **Action**: Instead of directly creating timer records with a hardcoded dict, override `_get_timer_vals()` to customize defaults, or call `self._create_timer(vals)`.
- **Files affected**: `*.py`

#### Rule: account_reconcile_cron_signature_change
- **Module**: `account_accountant`
- **Type**: signature_change
- **Old**: `_cron_try_auto_reconcile_statement_lines(self, batch_size=None, limit_time=0)`
- **New**: `_cron_try_auto_reconcile_statement_lines(self, batch_size=None, limit_time=0, company_id=None)`
- **Action**: If overriding this cron method, add `company_id=None` parameter. If calling it directly, no change needed (backward-compatible default).
- **Files affected**: `*.py`

#### Rule: approvals_to_store_signature_change
- **Module**: `approvals`
- **Type**: method_rename
- **Old**: `_to_store(self, store: Store)`
- **New**: `_to_store_defaults(self, target)`
- **Action**: Rename method override from `_to_store` to `_to_store_defaults`.
- **Files affected**: `*.py`

#### Rule: approvals_copy_method_changed
- **Module**: `approvals`
- **Type**: method_rename
- **Old**: `copy(self, default=None)` on `ApprovalApprover`
- **New**: `copy_data(self, default=None)` — now uses `copy_data` ORM pattern
- **Action**: If overriding `copy()` on approval approver, switch to `copy_data()`.
- **Files affected**: `*.py`

#### Rule: account_reports_post_init_hook_renamed
- **Module**: `account_reports`
- **Type**: method_rename
- **Old**: post_init_hook = `set_periodicity_journal_on_companies`
- **New**: post_init_hook = `_account_reports_post_init`
- **Action**: If calling the post-init hook by name, update the reference.
- **Files affected**: `__manifest__.py`, upgrade scripts

---

### XML View/Data Changes

#### Rule: sale_subscription_order_template_view_rename
- **Module**: `sale_subscription`
- **Type**: record_id_change
- **Old**: `views/sale_order_template.xml` (file) / `sale_subscription.view_order_tree` (xmlid)
- **New**: `views/sale_order_template_views.xml` / `sale_subscription.sale_order_tree`
- **Action**: Update any `inherit_id` references from `sale_subscription.view_order_tree` to `sale_subscription.sale_order_tree`.
- **Files affected**: `*.xml`

#### Rule: sale_subscription_order_line_view_rename
- **Module**: `sale_subscription`
- **Type**: view_id_change
- **Old**: `views/sale_order_line_view.xml`
- **New**: `views/sale_order_line_views.xml`
- **Action**: Update `inherit_id` references to views defined in this file.
- **Files affected**: `*.xml`

#### Rule: project_enterprise_sharing_template_rename
- **Module**: `project_enterprise`
- **Type**: view_id_change
- **Old**: `<template id="project_sharing_embed" inherit_id="project.project_sharing_embed">`
- **New**: `<template id="project_sharing_portal" inherit_id="project.project_sharing_portal">`
- **Action**: Update any inheritance from `project_enterprise.project_sharing_embed` to `project_enterprise.project_sharing_portal`.
- **Files affected**: `*.xml`

#### Rule: timesheet_grid_views_renamed
- **Module**: `timesheet_grid`
- **Type**: view_id_change
- **Old**: `views/hr_timesheet_views.xml`, `wizard/timesheet_merge_wizard_views.xml`, `wizard/project_task_create_timesheet_views.xml`
- **New**: `views/account_analytic_line_views.xml`, `wizard/hr_timesheet_merge_wizard_views.xml`, `wizard/hr_timesheet_stop_timer_confirmation_wizard_views.xml`
- **Action**: Update any `inherit_id` references to views defined in these files by finding the new xmlids in the renamed files.
- **Files affected**: `*.xml`

---

### JavaScript Changes

#### Rule: web_enterprise_color_scheme_export_removed
- **Module**: `web_enterprise`
- **Type**: export_removal
- **Old**: `export function switchColorSchemeItem(env)` from `@web_enterprise/webclient/color_scheme/color_scheme_service`
- **New**: Replaced by `systemColorScheme()` and `currentColorScheme()`
- **Action**: Replace `switchColorSchemeItem(env)` usage with `systemColorScheme()` or `currentColorScheme()` as appropriate.
- **Files affected**: `*.js`

#### Rule: web_gantt_get_range_from_date_removed
- **Module**: `web_gantt`
- **Type**: export_removal
- **Old**: `export function getRangeFromDate(rangeId, date)` from `@web_gantt/...`
- **New**: Replaced by `getScaleForCustomRange(params)`
- **Action**: Replace `getRangeFromDate()` calls with `getScaleForCustomRange()`. Check the new parameter structure.
- **Files affected**: `*.js`

#### Rule: web_gantt_resize_badge_removed
- **Module**: `web_gantt`
- **Type**: export_rename
- **Old**: `export class GanttResizeBadge extends Component`
- **New**: `export class GanttTimeDisplayBadge extends Component`
- **Action**: Replace `GanttResizeBadge` with `GanttTimeDisplayBadge` in imports and usage.
- **Files affected**: `*.js`, `*.xml`

#### Rule: web_gantt_multi_hover_signature_change
- **Module**: `web_gantt`
- **Type**: signature_change
- **Old**: `useMultiHover({ ref, selector, related, className })`
- **New**: `useMultiHover({ ref, selector, exception, related, className })` — new `exception` param added
- **Action**: Update call sites that destructure the options object. The new `exception` parameter is optional.
- **Files affected**: `*.js`

#### Rule: web_studio_dialog_button_rename
- **Module**: `web_studio`
- **Type**: export_rename
- **Old**: `export class DialogAddNewButton extends Component`
- **New**: `export class AddButtonAction extends Component`
- **Action**: Replace `DialogAddNewButton` with `AddButtonAction` in all imports.
- **Files affected**: `*.js`, `*.xml`

#### Rule: web_studio_make_model_error_resilient_signature
- **Module**: `web_studio`
- **Type**: signature_change
- **Old**: `makeModelErrorResilient(ModelClass)`
- **New**: `makeModelErrorResilient(ModelClass, activeActions = { create: true })`
- **Action**: No breaking change if calling without second argument. Update if you relied on behavior being create-only without specifying.
- **Files affected**: `*.js`

#### Rule: account_accountant_attachment_view_rename
- **Module**: `account_accountant`
- **Type**: export_rename
- **Old**: `export class AttachmentViewMoveLine extends AttachmentView`
- **New**: `export class AccountAttachmentView extends AttachmentView`
- **Action**: Replace `AttachmentViewMoveLine` with `AccountAttachmentView` in imports. Update any subclasses.
- **Files affected**: `*.js`

#### Rule: timesheet_timer_hook_removed
- **Module**: `timesheet_grid`
- **Type**: export_removal
- **Old**: `export class TimesheetTimerRendererHook` and `export function useTimesheetTimerRendererHook()`
- **New**: `export function useTimesheetTimer(isListView = false)`
- **Action**: Replace `useTimesheetTimerRendererHook()` with `useTimesheetTimer()`. For list view usage, call `useTimesheetTimer(true)`.
- **Files affected**: `*.js`

#### Rule: timesheet_grid_data_point_removed
- **Module**: `timesheet_grid`
- **Type**: export_removal
- **Old**: `TimesheetGridDataPoint` class, `TimerTimesheetGridDataPoint` class
- **New**: Replaced by `TimesheetGridModel`, `TimerTimesheetGridModel`
- **Action**: Extend `TimesheetGridModel` instead of `TimesheetGridDataPoint`. Update all subclasses.
- **Files affected**: `*.js`

#### Rule: spreadsheet_edition_list_patch_to_kanban
- **Module**: `spreadsheet_edition`
- **Type**: export_rename
- **Old**: `patchListControllerExportSelection`, `unpatchListControllerExportSelection`
- **New**: `patchKanbanControllerExportSelection`, `unpatchKanbanControllerExportSelection`
- **Action**: Replace list controller export selection patch with kanban controller patch. Update `useInsertInSpreadsheet(env, getExportableFields)` call signature.
- **Files affected**: `*.js`

#### Rule: project_gantt_model_mixin
- **Module**: `project_enterprise`
- **Type**: signature_change
- **Old**: `ProjectGanttModel extends GanttModel`
- **New**: `ProjectGanttModel extends ProjectModelMixin(GanttModel)` — new mixin pattern
- **Action**: If subclassing `ProjectGanttModel`, ensure your class still works with the mixin-based parent. Apply similar mixin pattern if needed.
- **Files affected**: `*.js`

---

### Security Group Changes

#### Rule: ir_module_category_to_res_groups_privilege
- **Module**: ALL modules (helpdesk, documents, approvals, sale_subscription, etc.)
- **Type**: xml_pattern_change
- **Old**:
  ```xml
  <record model="ir.module.category" id="base.module_category_X_Y">
    <field name="name">Module Name</field>
    <field name="description">...</field>
    <field name="sequence">N</field>
  </record>
  <record model="res.groups" id="group_X_user">
    <field name="category_id" ref="base.module_category_X_Y"/>
    <field name="users" eval="[(4, ref('base.user_root'))]"/>
  </record>
  ```
- **New**:
  ```xml
  <record model="res.groups.privilege" id="res_groups_privilege_X">
    <field name="name">Module Name</field>
    <field name="category_id" ref="base.module_category_parent"/>
  </record>
  <record model="res.groups" id="group_X_user">
    <field name="privilege_id" ref="res_groups_privilege_X"/>
    <field name="sequence">10</field>
    <field name="user_ids" eval="[(4, ref('base.user_root'))]"/>
  </record>
  ```
- **Action**: Replace `ir.module.category` inline category definitions with `res.groups.privilege` records. Change `category_id` in group definitions to `privilege_id`. Add `sequence` field to each group. Rename `users` to `user_ids` on `res.groups` records.
- **Files affected**: `security/*.xml`

#### Rule: users_field_renamed_to_user_ids
- **Module**: ALL modules with group definitions
- **Type**: xml_field_rename
- **Old**: `<field name="users" eval="[(4, ref('base.user_root')), ...]"/>`
- **New**: `<field name="user_ids" eval="[(4, ref('base.user_root')), ...]"/>`
- **Action**: In all security XML files, rename `<field name="users"` to `<field name="user_ids"` inside `res.groups` records.
- **Files affected**: `security/*.xml`

#### Rule: default_user_group_assignment_pattern
- **Module**: ALL modules that set default user groups
- **Type**: xml_pattern_change
- **Old**:
  ```xml
  <record id="base.default_user" model="res.users">
    <field name="groups_id" eval="[(4, ref('module.group_X'))]"/>
  </record>
  ```
- **New**:
  ```xml
  <record id="base.default_user_group" model="res.groups">
    <field name="implied_ids" eval="[(4, ref('module.group_X'))]"/>
  </record>
  ```
- **Action**: Replace `res.users.groups_id` assignment with `res.groups.implied_ids` assignment on `base.default_user_group`. This is the new pattern for setting default user permissions.
- **Files affected**: `security/*.xml`, `data/*.xml`

---

## Manifest Dependency Changes Summary

| Module | 18.0 depends | 19.0 depends | Change |
|--------|-------------|-------------|--------|
| `accountant` | `account_accountant` | `account_reports` | Major |
| `account_reports` | `accountant` | `account_accountant` | Major |
| `account_asset` | `account_reports` | `accountant` | Changed |
| `web_studio` | `..., web_editor, ...` | `web_editor` removed | Removed dep |
| `sale_subscription` | `..., base_automation, ...` | `base_automation` removed | Removed dep |
| `hr_appraisal` | `hr, calendar, web_gantt` | `calendar, hr_gantt` | Simplified |
| `hr_holidays_gantt` | `hr_holidays, web_gantt` | `hr_holidays, hr_gantt` | hr_gantt introduced |
| `account_loans` | unchanged | unchanged + `account_return_check_template.xml` data | Minor |

---

## Security Group Changes Summary

All major enterprise modules (helpdesk, documents, approvals, sale_subscription) migrated from the old `ir.module.category` + `category_id` pattern to the new `res.groups.privilege` + `privilege_id` pattern. The `users` field on `res.groups` was renamed to `user_ids`. Default user group assignment changed from modifying `res.users` to setting `implied_ids` on `res.groups`.

---

## Checklist for Module Migration

When migrating a custom enterprise module from 18.0 to 19.0:

1. **Renamed modules**: Check `__manifest__.py` for renamed modules listed above; update the module names.
2. **Test suite keys**: Rename `web.qunit_suite_tests` → `web.assets_unit_tests` in `__manifest__.py`.
3. **Security XML**: Update group definitions from `ir.module.category` to `res.groups.privilege`; rename `users` → `user_ids`; update default user assignments.
4. **Sale subscription**: Update manifest file references; update view xmlid `view_order_tree` → `sale_order_tree`.
5. **Documents**: Adapt to new sharing model and `res.groups.privilege` security pattern.
6. **Bank reconciliation**: Completely rewrite any extensions to bank reconciliation widget.
7. **Timesheet**: Replace `TimesheetGridDataPoint` with `TimesheetGridModel`; update timer hook to `useTimesheetTimer()`.
8. **Project Gantt**: Adapt to new mixin-based model pattern; update `project_sharing_embed` → `project_sharing_portal`.
9. **Account reports**: Update `accountant`/`account_reports` dependency chain; update `post_init_hook` name.
10. **Web Gantt**: Replace `getRangeFromDate` with `getScaleForCustomRange`; replace `GanttResizeBadge` with `GanttTimeDisplayBadge`.
11. **Web Studio**: Replace `DialogAddNewButton` with `AddButtonAction`.
12. **Spreadsheet**: Replace `patchListControllerExportSelection` with `patchKanbanControllerExportSelection`.