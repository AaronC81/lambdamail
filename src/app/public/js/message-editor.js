// Create the Vue app
const app = new Vue({
  el: "#details-form",
  data: { sections, sectionKinds, hasChanged: false },
  methods: {
    createSection: (e) => {
      // Get the selected option
      const select = e.target;
      const option = select.options[select.selectedIndex];
      
      console.log(option.dataset);

      // Create the new section
      sections.push({
        title: 'Untitled',
        plugin_package: option.dataset.package,
        plugin_id: option.dataset.id,
        properties: {}
      });

      // Put the select back to the "Please select..." options
      select.selectedIndex = 0;
    },

    updateTemplateFields: (e) => {
      const templateOption = e.target.options[e.target.selectedIndex];

      document.getElementsByName("template_plugin_package")[0].value = templateOption.dataset.package || '';
      document.getElementsByName("template_plugin_id")[0].value = templateOption.dataset.id || '';
    },

    modelChange: function() {
      this.hasChanged = true;
    }
  }
});

app.updateTemplateFields({ target: document.getElementById("template-select") });

window.onbeforeunload = function() {
  return "Are you sure you want to exit the message editor?";
}