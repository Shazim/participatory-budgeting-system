import { Controller } from "@hotwired/stimulus";

// Manages the lifecycle of a Bootstrap dropdown component to ensure it works
// correctly with Turbo page transitions.
export default class extends Controller {
  connect() {
    this.dropdown = new window.bootstrap.Dropdown(this.element);
  }

  disconnect() {
    if (this.dropdown) {
      this.dropdown.dispose();
    }
  }
}
