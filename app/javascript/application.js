// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "chartkick";
import "Chart.bundle";

// Import Bootstrap
import "bootstrap";

// Custom JavaScript for Participatory Budgeting
document.addEventListener("DOMContentLoaded", function () {
  // Initialize tooltips
  var tooltipTriggerList = [].slice.call(
    document.querySelectorAll('[data-bs-toggle="tooltip"]')
  );
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });

  // Initialize popovers
  var popoverTriggerList = [].slice.call(
    document.querySelectorAll('[data-bs-toggle="popover"]')
  );
  var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl);
  });

  // Auto-update progress bars
  function updateCategoryProgress() {
    document.querySelectorAll(".category-limit-bar").forEach(function (bar) {
      const used = parseFloat(bar.dataset.used || 0);
      const limit = parseFloat(bar.dataset.limit || 100);
      const percentage = Math.min((used / limit) * 100, 100);

      const progressBar = bar.querySelector(".category-used");
      if (progressBar) {
        progressBar.style.width = percentage + "%";

        // Update color based on usage
        progressBar.classList.remove(
          "category-safe",
          "category-warning",
          "category-danger"
        );
        if (percentage >= 90) {
          progressBar.classList.add("category-danger");
        } else if (percentage >= 75) {
          progressBar.classList.add("category-warning");
        } else {
          progressBar.classList.add("category-safe");
        }
      }
    });
  }

  updateCategoryProgress();

  // Real-time budget validation
  document.querySelectorAll('input[type="number"]').forEach(function (input) {
    if (input.name && input.name.includes("amount")) {
      input.addEventListener("input", function () {
        updateCategoryProgress();
      });
    }
  });

  // Form validation
  var forms = document.querySelectorAll(".needs-validation");
  Array.prototype.slice.call(forms).forEach(function (form) {
    form.addEventListener(
      "submit",
      function (event) {
        if (!form.checkValidity()) {
          event.preventDefault();
          event.stopPropagation();
        }
        form.classList.add("was-validated");
      },
      false
    );
  });
});
