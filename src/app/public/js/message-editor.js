// When the "Details" form is submitted, populate the template fields based on
// the selection in the dropdown
document.getElementById("details-form").onsubmit = () => {
  const templateSelect = document.getElementById("template-select");
  const templateOption = templateSelect.options[templateSelect.selectedIndex];

  document.getElementsByName("template_plugin_package")[0].value = templateOption.dataset.package;
  document.getElementsByName("template_plugin_id")[0].value = templateOption.dataset.id;
}