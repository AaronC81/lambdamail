function generateSectionKey() {
  return Math.floor(Math.random() * 10000000);
}

// Vue needs each section to have a key for fancy animations
// Let's just assign them randomly
// They don't need to be preserved, but it doesn't matter if they are
sections.forEach(section => {
  section.key = generateSectionKey();
});

// Create the Vue app
const app = new Vue({
  el: "#details-form",
  data: { sections, sectionKinds, hasChanged: false },
  methods: {
    createSection: (e) => {
      // Get the selected option
      const select = e.target;
      const option = select.options[select.selectedIndex];
      
      // Create the new section
      sections.push({
        key: generateSectionKey(),
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
    },

    moveSectionUp: function(index) {
      if (index == 0) return;
      [this.sections[index], this.sections[index - 1]] = [this.sections[index - 1], this.sections[index]];
      this.$forceUpdate();
    },

    moveSectionDown: function(index) {
      if (index == this.sections.length - 1) return;
      [this.sections[index], this.sections[index + 1]] = [this.sections[index + 1], this.sections[index]];
      this.$forceUpdate();
    },

    deleteSection: function(index) {
      this.sections.splice(index, 1);
      this.$forceUpdate();
    }
  }
});

app.updateTemplateFields({ target: document.getElementById("template-select") });

window.onbeforeunload = function() {
  return "Are you sure you want to exit the message editor?";
}