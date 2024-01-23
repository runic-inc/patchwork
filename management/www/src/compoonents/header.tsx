
export function Header() {
    return (
        <nav className="fixed top-0 left-0 right-0 z-10 bg-white shadow-md">
            <div className="flex justify-between items-center p-4">
                <div>
                    {/* Left-side content (if any) */}
                </div>
                <div className="flex items-center">
                    <w3m-button balance="hide" label="Connect" />
                </div>
            </div>
        </nav>
    );
}
