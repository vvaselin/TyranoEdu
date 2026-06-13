(function(global) {
  function $(id) {
    return document.getElementById(id);
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function setStatus(id, text, isError) {
    const el = $(id);
    if (!el) return;
    el.textContent = text;
    el.classList.toggle("error", !!isError);
    el.classList.toggle("ok", !isError && /件|完了|成功/.test(text));
  }

  function csvEscape(value) {
    const text = String(value == null || Number.isNaN(value) ? "" : value);
    return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
  }

  function downloadFile(filename, text, type) {
    const blob = new Blob([text], { type });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  function downloadCSV(filename, headers, rows) {
    const body = [headers.join(","), ...rows.map((row) => row.map(csvEscape).join(","))].join("\r\n");
    downloadFile(filename, "\uFEFF" + body, "text/csv;charset=utf-8");
  }

  global.AdminUI = { $, escapeHtml, setStatus, csvEscape, downloadFile, downloadCSV };
})(window);
