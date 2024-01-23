
import Commands from './views/commands';
import { Toaster } from 'react-hot-toast';
import { Route, BrowserRouter as Router, Routes } from 'react-router-dom';
import './App.css';
import { Header } from './compoonents/header';

function App() {
    return (
        <Router>
            <Toaster
                containerStyle={{ inset: '2.5rem' }}
                position="top-center"
                reverseOrder={false}
                toastOptions={{
                    className: '!rounded-xl min-h-[3rem] !text-slate-500',
                    style: {},
                }}
            />
            <Header />
            <Routes>
                <Route path="/" element={<Commands />} />
            </Routes>
        </Router>
    );
}

export default App;
