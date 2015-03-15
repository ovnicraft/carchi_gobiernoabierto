/* Change create element method of AJjax.InPlaceEditor */
Ajax.InPlaceEditorWithAutocompleter = Class.create(Ajax.InPlaceEditor, {
  initialize: function($super, element, url, options) {
    options.inputId = options["inputID"] || "in_place_input_field";
    $super(element, url, options);
  },
  //
  // Create form input filed with ID to be used for the Autocompleter.
  //
  createEditField: function() {
    var text = (this.options.loadTextURL ? this.options.loadingText : this.getText());
    var fld;
    if (1 >= this.options.rows && !/\r|\n/.test(this.getText())) {
      fld = document.createElement('input');
      fld.type = 'text';
      var size = this.options.size || this.options.cols || 0;
      if (0 < size) fld.size = size;
    } else {
      fld = document.createElement('textarea');
      fld.rows = (1 >= this.options.rows ? this.options.autoRows : this.options.rows);
      fld.cols = this.options.cols || 40;
    }
    fld.id = this.options.inputId;
    fld.name = this.options.paramName;
    fld.value = text; // No HTML breaks conversion anymore
    fld.className = 'editor_field';
    if (this.options.submitOnBlur)
      fld.onblur = this._boundSubmitHandler;
    this._controls.editor = fld;
    if (this.options.loadTextURL)
      this.loadExternalText();
    this._form.appendChild(this._controls.editor);
  },
  
  //
  // After the form is created we initialize the Autocompleter.
  //
  enterEditMode: function(e) {
      if (this._saving || this._editing) return;
      this._editing = true;
      this.triggerCallback('onEnterEditMode');
      if (this.options.externalControl)
        this.options.externalControl.hide();
      this.element.hide();
      this.createForm();
      this.element.parentNode.insertBefore(this._form, this.element);
      
      var ac_options = {}
      if (this.options.indicator)
        ac_options.indicator = this.options.indicator;
      var in_place_auto_completer = new Ajax.Autocompleter(this.options.inputID, this.options.inputID+'_auto_complete', this.options.autocompleterUrl, ac_options);

      if (!this.options.loadTextURL)
        this.postProcessEditField();
      if (e) Event.stop(e);
    }
});
