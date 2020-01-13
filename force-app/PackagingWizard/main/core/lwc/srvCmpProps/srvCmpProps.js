export default class SrvCmpProps {
    constructor({ name, label, value, placeholder, options, required, variant, title, disabled, type, className }) {
        this.name = name || "";
        this.label = label || "";
        this.value = value || null;
        this.placeholder = placeholder || "Select an Option";
        this.options = options || [];
        this.required = required || false;
        this.variant = variant || "brand";
        this.title = title || "";
        this.disabled = disabled || false;
        this.type = type || null;
        this.className = className || "";
    }
};