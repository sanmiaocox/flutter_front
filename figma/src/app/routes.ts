import { createBrowserRouter } from "react-router";
import HomePage from "./HomePage";
import FeedDetail from "./FeedDetail";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: HomePage,
  },
  {
    path: "/feed/:id",
    Component: FeedDetail,
  },
]);
