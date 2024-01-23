/** @type {import("tailwindcss").Config} */

export default {
    content: ['./src/**/*.{js,jsx,ts,tsx}'],
    plugins: [require('@headlessui/tailwindcss')],
    safelist: ['bubble-left', 'bubble-right', 'bubble-mint'],
};
