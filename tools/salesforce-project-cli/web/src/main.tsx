/**
 * Mounts the browser dashboard with Aksel styling, Nynorsk locale, and the production API client.
 * Importing this module renders into the required `root` element.
 */
import '@navikt/ds-css';
import { Provider } from '@navikt/ds-react';
import { nn } from '@navikt/ds-react/locales';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App';
import { browserApi } from './api';
import './styles.css';

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <Provider locale={nn}>
            <App api={browserApi} />
        </Provider>
    </StrictMode>
);
