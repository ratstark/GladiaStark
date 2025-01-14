import type { NextConfig } from "next";

import mkcert from "vite-plugin-mkcert";

const nextConfig: NextConfig = {
    plugins: [mkcert()],
};

export default nextConfig;
