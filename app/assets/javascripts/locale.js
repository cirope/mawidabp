document.addEventListener('DOMContentLoaded', () => {
  const localeSelector = document.querySelector('[data-locale-selector]');

  if (localeSelector) {
    localeSelector.addEventListener('change', (event) => {
      changeLocale(event.target.value);
    });
  }
});

function changeLocale(locale) {
  const url = new URL(window.location.href);

  url.searchParams.set('locale', locale);
  window.location.href = url.toString();
}
