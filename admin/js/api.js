(function(global) {
  const AdminAPI = {
    password: "",
    setPassword(value) {
      this.password = value || "";
      try {
        sessionStorage.setItem("admin_password", this.password);
      } catch (_) {}
    },
    getPassword() {
      if (this.password) return this.password;
      try {
        this.password = sessionStorage.getItem("admin_password") || "";
      } catch (_) {
        this.password = "";
      }
      return this.password;
    },
    headers(extra) {
      return Object.assign({ "X-Admin-Password": this.getPassword() }, extra || {});
    },
    async fetchJSON(url, options) {
      const res = await fetch(url, Object.assign({ headers: this.headers() }, options || {}));
      const text = await res.text();
      let data = {};
      try {
        data = text ? JSON.parse(text) : {};
      } catch (_) {
        data = {};
      }
      if (!res.ok) throw new Error(data.error || text || `HTTP ${res.status}`);
      return data;
    },
    postJSON(url, body) {
      return this.fetchJSON(url, {
        method: "POST",
        headers: this.headers({ "Content-Type": "application/json" }),
        body: JSON.stringify(body || {}),
      });
    },
  };
  global.AdminAPI = AdminAPI;
})(window);
